require 'spec_helper'

describe Gembrew::CLI do
  subject(:runner) { described_class.runner }

  it 'returns a MisterBin runner' do
    expect(runner).to be_a MisterBin::Runner
  end

  it 'shows the available commands' do
    expect { runner.run }.to output_approval('cli/commands')
  end

  it 'shows command help' do
    expect { runner.run %w[init --help] }.to output_approval('cli/init-help')
  end

  it 'shows the version' do
    expect { runner.run %w[--version] }.to output("#{Gembrew::VERSION}\n").to_stdout
  end
end

