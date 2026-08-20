require 'spec_helper'

describe Gembrew::CLI do
  subject { described_class.runner }

  it 'returns a MisterBin runner' do
    expect(subject).to be_a MisterBin::Runner
  end

  it 'shows the available commands' do
    expect { subject.run }.to output_approval('cli/commands')
  end

  it 'shows command help' do
    expect { subject.run %w[init --help] }.to output_approval('cli/init-help')
  end

  it 'shows the version' do
    expect { subject.run %w[--version] }.to output("#{Gembrew::VERSION}\n").to_stdout
  end
end
