require 'spec_helper'

describe Gembrew::DockerShell do
  subject { described_class.new runner: runner }

  let(:runner) { double call: true }

  it 'opens an interactive Homebrew container' do
    expect(runner).to receive(:call).with('bash', '--norc', interactive: true, pristine: false)
    expect(subject.call).to be true
  end

  it 'opens a pristine interactive Homebrew container' do
    expect(runner).to receive(:call).with('bash', '--norc', interactive: true, pristine: true)
    expect(subject.call(pristine: true)).to be true
  end

  context 'when the shell fails' do
    let(:runner) { double call: false }

    it 'reports a failed shell' do
      expect { subject.call }.to raise_error(Gembrew::Error, 'Homebrew shell exited with an error')
    end
  end
end
