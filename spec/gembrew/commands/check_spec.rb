require 'spec_helper'

describe Gembrew::Commands::Check do
  subject { described_class }

  let(:generator) { instance_double Gembrew::Generator, call: formula_path }
  let(:check) { instance_double Gembrew::DockerCheck, call: true }
  let(:config) { instance_double Gembrew::Config, name: 'example' }
  let(:formula_path) { Pathname '/tap/Formula/example.rb' }

  before do
    allow(Gembrew::Generator).to receive(:new).and_return generator
    allow(Gembrew::DockerCheck).to receive(:new).and_return check
    allow(Gembrew::Config).to receive(:all).and_return [config]
  end

  it 'builds the formula and runs the Homebrew checks' do
    expect(generator).to receive(:call)
    expect(check).to receive(:call).with('example')

    expect { subject.execute %w[check] }.to output_approval('commands/check')
  end

  context 'with an output name that differs from the configuration name' do
    let(:formula_path) { Pathname '/tap/Formula/example-cli.rb' }

    it 'checks the generated formula name' do
      expect(check).to receive(:call).with('example-cli')
      subject.execute %w[check]
    end
  end
end
