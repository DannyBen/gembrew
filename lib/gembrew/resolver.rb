require 'bundler'
require 'digest'
require 'open3'
require 'pathname'
require 'rubygems/package'
require 'tmpdir'
require 'gembrew/archive_store'
require 'gembrew/error'
require 'gembrew/reporter'

module Gembrew
  Resource = Data.define(:name, :version, :sha256)
  Resolution = Data.define(:spec, :sha256, :resources)

  class Resolver
    attr_reader :cache_root

    def initialize(cache_root: nil, reporter: Reporter.new, command_runner: nil, archive_store: nil)
      @cache_root = Pathname(cache_root || default_cache_root)
      @reporter = reporter
      @command_runner = command_runner || method(:run_command)
      @archive_store = archive_store || ArchiveStore.new(
        cache_path: @cache_root/'gems', reporter: reporter, command_runner: @command_runner
      )
      temporary_root.mkpath
    end

    def resolve(name, version = nil)
      Dir.mktmpdir('build-', temporary_root.to_s) do |directory|
        temporary = Pathname(directory)
        root_archive = archive_store.fetch(name, version, temporary)
        root_spec = Gem::Package.new(root_archive.to_s).spec
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
      gemfile.write <<~RUBY
        source "https://rubygems.org"
        gem #{root_spec.name.inspect}, "= #{root_spec.version}"
      RUBY

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
