require 'fileutils'
require 'open3'
require 'pathname'
require 'rubygems/package'
require 'gembrew/error'
require 'gembrew/reporter'

module Gembrew
  class ArchiveStore
    attr_reader :cache_path

    def initialize(cache_path:, reporter: Reporter.new, command_runner: nil)
      @cache_path = Pathname(cache_path)
      @reporter = reporter
      @command_runner = command_runner || method(:run_command)
      @cache_path.mkpath
    end

    def fetch(name, version, download_path, index: nil, total: nil)
      if (path = locally_cached(name, version))
        report :rubygems_cache, name, version, index: index, total: total
        return path
      end

      if version && (path = gembrew_cached(name, version))
        report :gembrew_cache, name, version, index: index, total: total
        return path
      end

      download name, version, Pathname(download_path), index: index, total: total
    end

  private

    attr_reader :reporter, :command_runner

    def locally_cached(name, version)
      return unless version

      Gem.path.each do |gem_path|
        path = Pathname(gem_path)/'cache'/"#{name}-#{version}.gem"
        return path if valid_archive?(path, name, version)
      end

      nil
    end

    def gembrew_cached(name, version)
      path = cache_path/"#{name}-#{version}.gem"
      path if valid_archive?(path, name, version)
    end

    def valid_archive?(path, name, version)
      return false unless path.file?

      spec = Gem::Package.new(path.to_s).spec
      spec.name == name && spec.version == Gem::Version.new(version.to_s) &&
        spec.platform == Gem::Platform::RUBY
    rescue Gem::Package::Error
      false
    end

    def download(name, version, download_path, index:, total:)
      report :downloading, name, version, index: index, total: total
      before = download_path.children
      command = ['gem', 'fetch', name, '--platform', 'ruby']
      command.push '--version', version.to_s if version
      command_runner.call(*command, chdir: download_path)

      candidates = download_path.children - before
      archive = candidates.find { |path| path.extname == '.gem' }
      raise Error, "gem fetch did not produce a .gem file for #{name} #{version}" unless archive

      spec = Gem::Package.new(archive.to_s).spec
      cached_path = cache_path/"#{spec.name}-#{spec.version}.gem"
      FileUtils.mv archive, cached_path, force: true
      cached_path
    end

    def report(state, name, version, index:, total:)
      reporter.archive state, name, version, index: index, total: total
    end

    def run_command(*command, chdir:)
      result, status = Open3.capture2e(*command, chdir: chdir.to_s)
      raise Error, result unless status.success?

      result
    end
  end
end
