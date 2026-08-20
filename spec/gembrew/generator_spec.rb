require 'spec_helper'
require 'tmpdir'

describe Gembrew::Generator do
  subject { described_class.new config: config, resolver: resolver }

  let(:directory) { Pathname Dir.mktmpdir }
  let(:output_path) { directory/'Formula/example_cli.rb' }
  let(:config) do
    instance_double Gembrew::Config,
      gem_name: 'example_cli', version: nil, output_path: output_path,
      description: nil, homepage: nil, license: nil, executable: nil,
      repository: 'https://github.com/bashly-framework/homebrew-tap',
      dependencies: ['bash'],
      test_body: %[system bin/"example", "--version"]
  end
  let(:resolution) do
    gem_spec = Gem::Specification.new do |gem|
      gem.name = 'example_cli'
      gem.version = '1.2.3'
      gem.summary = 'Example CLI'
      gem.homepage = 'https://example.com'
      gem.license = 'MIT'
      gem.executables = ['example']
    end

    Gembrew::Resolution.new(
      gem_spec,
      'root-checksum',
      [Gembrew::Resource.new('dependency', '2.0.0', 'dependency-checksum')]
    )
  end
  let(:resolver) { instance_double Gembrew::Resolver }

  before { allow(resolver).to receive(:resolve).with('example_cli', nil).and_return resolution }
  after { directory.rmtree }

  it 'renders a complete formula using inferred metadata and resolved resources' do
    expect(subject.call).to eq output_path
    expect(output_path.read).to match_approval('generator/formula')
  end

  it 'omits the header when no repository is configured' do
    allow(config).to receive(:repository).and_return nil
    subject.call
    expect(output_path.read).to start_with "class ExampleCli < Formula\n"
  end
end
