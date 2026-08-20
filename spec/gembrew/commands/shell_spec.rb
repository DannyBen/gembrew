require 'spec_helper'

describe Gembrew::Commands::Shell do
  it 'opens the Homebrew shell' do
    shell = instance_double(Gembrew::DockerShell, call: true)
    allow(Gembrew::DockerShell).to receive(:new).and_return shell

    expect { described_class.execute %w[shell] }.not_to output.to_stdout
    expect(shell).to have_received(:call)
  end
end
