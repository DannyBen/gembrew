require 'spec_helper'

describe Gembrew::Commands::Check do
  it 'builds the formula and runs the Homebrew checks' do
    generator = instance_double(Gembrew::Generator, call: Pathname('/tap/Formula/example.rb'))
    check = instance_double(Gembrew::DockerCheck, call: true)
    allow(Gembrew::Generator).to receive(:new).and_return generator
    allow(Gembrew::DockerCheck).to receive(:new).and_return check

    expect { described_class.execute %w[check] }.to output(<<~OUTPUT).to_stdout
      Generated /tap/Formula/example.rb
      All checks passed
    OUTPUT
    expect(generator).to have_received(:call)
    expect(check).to have_received(:call)
  end
end
