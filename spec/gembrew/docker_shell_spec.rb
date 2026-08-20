require 'spec_helper'
require 'tmpdir'

describe Gembrew::DockerShell do
  it 'opens the generated Docker Compose service' do
    Dir.mktmpdir do |directory|
      compose_path = Pathname(directory)/'support/compose.yaml'
      compose_path.dirname.mkpath
      compose_path.write "services: {}\n"
      invocation = nil
      runner = lambda do |*command, chdir:|
        invocation = { command: command, chdir: chdir }
        true
      end

      result = described_class.new(project_path: directory, command_runner: runner).call

      expect(result).to be true
      expect(invocation).to eq(
        command: %w[docker compose -f support/compose.yaml run --rm brew],
        chdir:   Pathname(directory)
      )
    end
  end

  it 'requires the generated Compose file' do
    Dir.mktmpdir do |directory|
      expect { described_class.new(project_path: directory).call }
        .to raise_error(
          Gembrew::Error,
          "Compose file does not exist: #{directory}/support/compose.yaml"
        )
    end
  end

  it 'reports a failed shell' do
    Dir.mktmpdir do |directory|
      compose_path = Pathname(directory)/'support/compose.yaml'
      compose_path.dirname.mkpath
      compose_path.write "services: {}\n"
      runner = ->(*_, chdir:) { false }

      expect do
        described_class.new(project_path: directory, command_runner: runner).call
      end.to raise_error(Gembrew::Error, 'Homebrew shell exited with an error')
    end
  end

  it 'runs commands with inherited input and output' do
    shell = described_class.allocate

    expect(shell).to receive(:system).with('command', chdir: '/tap').and_return true
    expect(shell.send(:run_command, 'command', chdir: Pathname('/tap'))).to be true
  end
end
