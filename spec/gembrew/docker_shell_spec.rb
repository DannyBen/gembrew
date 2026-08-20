require 'spec_helper'

describe Gembrew::DockerShell do
  subject { described_class.new project_path: project_path, command_runner: runner }

  let(:project_path) { fixture 'compose' }
  let(:runner) { double call: true }

  it 'opens the generated Docker Compose service' do
    expect(runner).to receive(:call).with(
      *%w[docker compose -f support/compose.yaml run --rm brew],
      chdir: Pathname(project_path)
    )
    expect(subject.call).to be true
  end

  context 'without a Compose file' do
    let(:project_path) { fixture 'missing-compose' }

    it 'requires the generated Compose file' do
      expect { subject.call }.to raise_error(
        Gembrew::Error,
        "Compose file does not exist: #{project_path}/support/compose.yaml"
      )
    end
  end

  context 'when the shell fails' do
    let(:runner) { double call: false }

    it 'reports a failed shell' do
      expect { subject.call }.to raise_error(Gembrew::Error, 'Homebrew shell exited with an error')
    end
  end

  describe '#run_command' do
    let(:shell) { described_class.allocate }

    it 'runs commands with inherited input and output' do
      allow(shell).to receive(:system).with('command', chdir: '/tap').and_return true
      expect(shell.send(:run_command, 'command', chdir: Pathname('/tap'))).to be true
    end
  end
end
