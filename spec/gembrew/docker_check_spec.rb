require 'spec_helper'

describe Gembrew::DockerCheck do
  subject { described_class.new project_path: project_path, command_runner: runner }

  let(:project_path) { fixture 'compose' }
  let(:runner) { double call: true }

  it 'runs the generated check service without a TTY' do
    expect(runner).to receive(:call).with(
      *%w[docker compose -f support/compose.yaml run --rm --no-TTY check],
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

  context 'when the check fails' do
    let(:runner) { double call: false }

    it 'reports failed checks' do
      expect { subject.call }.to raise_error(Gembrew::Error, 'Homebrew checks failed')
    end
  end

  describe '#run_command' do
    let(:check) { described_class.allocate }

    it 'streams command output' do
      allow(check).to receive(:system).with('command', chdir: '/tap').and_return true
      expect(check.send(:run_command, 'command', chdir: Pathname('/tap'))).to be true
    end
  end
end
