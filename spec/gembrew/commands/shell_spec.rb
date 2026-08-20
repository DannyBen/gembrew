require 'spec_helper'

describe Gembrew::Commands::Shell do
  subject { described_class }

  let(:shell) { instance_double Gembrew::DockerShell, call: true }

  before { allow(Gembrew::DockerShell).to receive(:new).and_return shell }

  it 'opens the Homebrew shell' do
    expect(shell).to receive(:call)

    expect { subject.execute %w[shell] }.not_to output.to_stdout
  end
end
