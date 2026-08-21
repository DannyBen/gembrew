require 'bundler'
require 'digest'
require 'open3'
require 'pathname'
require 'rubygems/package'
require 'tmpdir'
require 'gembrew/archive_store'
require 'gembrew/error'
require 'gembrew/github_archive_store'
require 'gembrew/reporter'

module Gembrew
  Resource = Data.define(:name, :version, :sha256)
  Resolution = Data.define(:spec, :sha256, :resources)

  class Resolver
    attr_reader :cache_root

    def initialize(cache_root: nil, reporter: Reporter.new, command_runner: nil, archive_store: nil,
      github_archive_store: nil)
      @cache_root = Pathname(cache_root || default_cache_root)
      @reporter = reporter
      @command_runner = command_runner || method(:run_command)
      @archive_store = archive_store || ArchiveStore.new(
        cache_path: @cache_root/'gems', reporter: reporter, command_runner: @command_runner
      )
      @github_archive_store = github_archive_store
      temporary_root.mkpath
    end

    def resolve(name, version, source:)
      Dir.mktmpdir('build-', temporary_root.to_s) do |directory|
        temporary = Pathname(directory)
        root_archive, root_spec = root_source name, version, source, temporary
        dependencies = dependency_specs(lock(root_spec, temporary), root_spec)

        reporter.collecting dependencies.length
        resources = dependencies.each_with_index.map do |spec, index|
          resource spec, temporary, index + 1, dependencies.length
        end

        Resolution.new(root_spec, Digest::SHA256.file(root_archive).hexdigest, resources)
      end
    end

  private

    attr_reader :reporter, :command_runner, :archive_store

    def github_archive_store
      @github_archive_store ||= GithubArchiveStore.new(
        cache_path: cache_root/'github', reporter: reporter, command_runner: command_runner
      )
    end

    def root_source(name, version, source_config, temporary)
      if source_config.fetch('type') == 'rubygems'
        archive = archive_store.fetch(name, version, temporary)
        return [archive, Gem::Package.new(archive.to_s).spec]
      end

      repository = source_config.fetch('repo')
      tag = source_config['tag'] || "v#{version}"
      gemspec_path = source_config['gemspec'] || "#{name}.gemspec"
      archive = github_archive_store.fetch repository, tag
      extracted = github_archive_store.extract archive, temporary/'source'
      roots = extracted.children.select(&:directory?)
      raise Error, 'Expected one project directory in the GitHub archive' unless roots.one?

      gemspec = roots.first/gemspec_path
      raise Error, "Gemspec not found in GitHub archive: #{gemspec_path}" unless gemspec.file?
      spec = Dir.chdir(gemspec.dirname) { Gem::Specification.load(gemspec.basename.to_s) }
      raise Error, "Could not load gemspec from GitHub archive: #{gemspec_path}" unless spec
      raise Error, "Gemspec name #{spec.name} does not match configured gem #{name}" unless spec.name == name
      raise Error, "GitHub gemspec version #{spec.version} does not match #{version}" unless spec.version == Gem::Version.new(version)

      [archive, spec]
    end

    def resource(spec, temporary, index, total)
      archive = archive_store.fetch spec.name, spec.version, temporary, index: index, total: total
      Resource.new spec.name, spec.version.to_s, Digest::SHA256.file(archive).hexdigest
    end

    def default_cache_root
      cache_home = ENV.fetch('XDG_CACHE_HOME', File.expand_path('~/.cache'))
      Pathname(cache_home)/'gembrew'
    end

    def temporary_root
      cache_root/'tmp'
    end

    def lock(root_spec, temporary)
      gemfile = temporary/'Gemfile'
      lockfile = temporary/'Gemfile.lock'
      dependencies = root_spec.runtime_dependencies.map do |dependency|
        requirements = dependency.requirement.requirements.map { |operator, version| "#{operator} #{version}" }
        "gem #{dependency.name.inspect}, #{requirements.map(&:inspect).join(', ')}"
      end
      gemfile.write([[%(source "https://rubygems.org")], dependencies, ['']].flatten.join("\n"))

      reporter.resolving root_spec.name, root_spec.version
      command_runner.call(
        'bundle', 'lock', '--gemfile', gemfile.to_s, '--lockfile', lockfile.to_s,
        '--add-platform', 'ruby',
        chdir: temporary,
        env:   {
          'BUNDLE_FORCE_RUBY_PLATFORM' => 'true',
          'BUNDLE_GEMFILE'             => gemfile.to_s,
        }
      )
      lockfile
    end

    def dependency_specs(lockfile, root_spec)
      specs = Bundler::LockfileParser.new(lockfile.read).specs
      selected = specs.group_by(&:name).values.map do |variants|
        variants.find { |spec| spec.platform == Gem::Platform::RUBY } || variants.first
      end

      selected.reject { |spec| spec.name == root_spec.name }.sort_by(&:name)
    end

    def run_command(*command, chdir:, env: {})
      result, status = Open3.capture2e(env, *command, chdir: chdir.to_s)
      raise Error, result unless status.success?

      result
    end
  end
end
