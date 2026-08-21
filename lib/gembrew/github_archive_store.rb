require 'fileutils'
require 'open3'
require 'pathname'
require 'gembrew/error'
require 'gembrew/reporter'

module Gembrew
  class GithubArchiveStore
    def initialize(cache_path:, reporter: Reporter.new, command_runner: nil)
      @cache_path = Pathname(cache_path)
      @reporter = reporter
      @command_runner = command_runner || method(:run_command)
      @cache_path.mkpath
    end

    def fetch(repository, tag)
      name = repository.tr '/', '-'
      path = @cache_path/"#{name}-#{tag.tr '/', '-'}.tar.gz"
      if path.file? && !path.empty?
        reporter.archive :github_cache, repository, tag
        return path
      end

      reporter.archive :downloading, repository, tag
      url = "https://github.com/#{repository}/archive/refs/tags/#{tag}.tar.gz"
      command_runner.call 'curl', '--fail', '--location', '--silent', '--show-error',
        '--output', path.to_s, url, chdir: @cache_path
      raise Error, "GitHub archive is empty: #{url}" unless path.file? && !path.empty?

      path
    end

    def extract(archive, destination)
      destination = Pathname(destination)
      destination.mkpath
      command_runner.call 'tar', '-xzf', archive.to_s, '-C', destination.to_s, chdir: destination
      destination
    end

  private

    attr_reader :reporter, :command_runner

    def run_command(*command, chdir:)
      result, status = Open3.capture2e(*command, chdir: chdir.to_s)
      raise Error, result unless status.success?

      result
    end
  end
end
