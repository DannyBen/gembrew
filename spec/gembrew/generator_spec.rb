require 'spec_helper'
require 'tmpdir'

describe Gembrew::Generator do
  subject { described_class.new config: config, resolver: resolver }

  let(:directory) { Pathname Dir.mktmpdir }
  let(:output_path) { directory/'Formula/example_cli.rb' }
  let(:config) do
    instance_double Gembrew::Config,
      gem_name: 'example_cli', version: '1.2.3', output_path: output_path,
      description: nil, homepage: nil, license: nil, executable: nil,
      source: { 'type' => 'github', 'repo' => 'bashly-framework/bashly' },
      source_type: 'github', source_repo: 'bashly-framework/bashly',
      source_tag: 'v1.2.3', source_gemspec: 'example_cli.gemspec',
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

  before do
    allow(resolver).to receive(:resolve)
      .with('example_cli', '1.2.3', source: {
        'type' => 'github', 'repo' => 'bashly-framework/bashly'
      })
      .and_return resolution
  end
  after { directory.rmtree }

  it 'renders a complete formula using inferred metadata and resolved resources' do
    expect(subject.call).to eq output_path
    expect(output_path.read).to match_approval('generator/formula')
  end
end
