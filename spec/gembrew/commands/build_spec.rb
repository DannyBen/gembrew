require 'spec_helper'

describe Gembrew::Commands::Build do
  it 'generates the formula' do
    config = instance_double Gembrew::Config, name: 'example'
    generator = instance_double(Gembrew::Generator, call: Pathname('/tap/Formula/example.rb'))
    allow(Gembrew::Config).to receive(:all).and_return [config]
    allow(Gembrew::Generator).to receive(:new).and_return generator

    expect { described_class.execute %w[build] }
      .to output("==> gembrew: building example\nGenerated /tap/Formula/example.rb\n").to_stdout
  end

  it 'generates one selected formula' do
    config = instance_double Gembrew::Config, name: 'example'
    generator = instance_double(Gembrew::Generator, call: Pathname('/tap/Formula/example.rb'))
    allow(Gembrew::Config).to receive(:find).with('example').and_return config
    allow(Gembrew::Generator).to receive(:new).with(config: config).and_return generator

    expect { described_class.execute %w[build example] }
      .to output(/building example/).to_stdout
  end
end
