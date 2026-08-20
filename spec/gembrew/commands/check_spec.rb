require 'spec_helper'

describe Gembrew::Commands::Check do
  subject { described_class }

  let(:generator) { instance_double Gembrew::Generator, call: formula_path }
  let(:check) { instance_double Gembrew::DockerCheck, call: true }
  let(:formula_path) { Pathname '/tap/Formula/example.rb' }

  before do
    allow(Gembrew::Generator).to receive(:new).and_return generator
    allow(Gembrew::DockerCheck).to receive(:new).and_return check
  end

  it 'builds the formula and runs the Homebrew checks' do
    expect(generator).to receive(:call)
    expect(check).to receive(:call)

    expect { subject.execute %w[check] }.to output_approval('commands/check')
  end
end
