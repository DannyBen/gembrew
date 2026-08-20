require 'spec_helper'

describe Gembrew::Commands::Build do
  it 'generates the formula' do
    generator = instance_double(Gembrew::Generator, call: Pathname('/tap/Formula/example.rb'))
    allow(Gembrew::Generator).to receive(:new).and_return generator

    expect { described_class.execute %w[build] }
      .to output("Generated /tap/Formula/example.rb\n").to_stdout
  end
end
