require 'gembrew/docker_runner'
require 'gembrew/error'

module Gembrew
  class DockerShell
    def initialize(runner: DockerRunner.new)
      @runner = runner
    end

    def call
      success = runner.call 'bash', '--norc', interactive: true
      raise Error, 'Homebrew shell exited with an error' unless success

      true
    end

  private

    attr_reader :runner
  end
end
