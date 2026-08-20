require 'pathname'
require 'gembrew/error'

module Gembrew
  class DockerCheck
    COMPOSE_PATH = Pathname('support/compose.yaml')

    attr_reader :project_path

    def initialize(project_path: Pathname.pwd, command_runner: nil)
      @project_path = Pathname(project_path).expand_path
      @command_runner = command_runner || method(:run_command)
    end

    def call
      raise Error, "Compose file does not exist: #{compose_path}" unless compose_path.file?

      success = command_runner.call(
        'docker', 'compose', '-f', COMPOSE_PATH.to_s,
        'run', '--rm', '--no-TTY', 'check',
        chdir: project_path
      )
      raise Error, 'Homebrew checks failed' unless success

      true
    end

  private

    attr_reader :command_runner

    def compose_path
      project_path/COMPOSE_PATH
    end

    def run_command(*command, chdir:)
      system(*command, chdir: chdir.to_s)
    end
  end
end
