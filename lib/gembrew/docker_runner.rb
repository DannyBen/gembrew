require 'pathname'

module Gembrew
  class DockerRunner
    IMAGE = 'homebrew/brew:main'
    TAP_PATH = '/home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/gembrew/homebrew-tap'

    attr_reader :project_path

    def initialize(project_path: Pathname.pwd, command_runner: nil)
      @project_path = Pathname(project_path).expand_path
      @command_runner = command_runner || method(:run_command)
    end

    def call(*command, interactive: false, pristine: false)
      docker_command = ['docker', 'run', '--rm', '--init', '--name', container_name]
      docker_command << '--pull=always' if pristine
      docker_command << '-it' if interactive
      docker_command.concat environment(interactive: interactive, pristine: pristine)
      unless pristine
        docker_command.push '--workdir', '/work'
        docker_command.push '--volume', "#{project_path}:/work"
        docker_command.push '--volume', "#{project_path}:#{TAP_PATH}"
      end
      docker_command << IMAGE
      docker_command.concat command
      command_runner.call(*docker_command, chdir: project_path)
    end

  private

    attr_reader :command_runner

    def environment(interactive:, pristine:)
      result = if pristine
        []
      else
        %w[
          --env HOMEBREW_NO_AUTO_UPDATE=1
          --env HOMEBREW_NO_INSTALL_CLEANUP=1
          --env HOMEBREW_NO_INSTALL_FROM_API=1
        ]
      end
      prompt = pristine ? 'homebrew' : 'gembrew'
      result.push '--env', "PS1=\\n\\n#{prompt} $ " if interactive
      result
    end

    def run_command(*command, chdir:)
      success = system(*command, chdir: chdir.to_s)
      cleanup_container command unless success
      success
    rescue Interrupt
      previous_handler = Signal.trap 'INT', 'IGNORE'
      begin
        cleanup_container command
      ensure
        Signal.trap 'INT', previous_handler
      end
      raise
    end

    def container_name
      "gembrew-#{Process.pid}"
    end

    def cleanup_container(command)
      name = command.fetch(command.index('--name') + 1)
      system 'docker', 'rm', '--force', name, out: File::NULL, err: File::NULL
    end
  end
end
