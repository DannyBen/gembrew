require 'gembrew/docker_runner'
require 'gembrew/error'

module Gembrew
  class DockerShell
    def initialize(runner: DockerRunner.new)
      @runner = runner
    end

    def call(pristine: false)
      success = runner.call 'bash', '--norc', interactive: true, pristine: pristine
      raise Error, 'Homebrew shell exited with an error' unless success

      true
    end

  private

    attr_reader :runner
  end
end
