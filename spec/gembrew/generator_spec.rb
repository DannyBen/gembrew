require 'spec_helper'
require 'tmpdir'

describe Gembrew::Generator do
  it 'renders a complete formula using inferred metadata and resolved resources' do
    Dir.mktmpdir do |directory|
      output_path = Pathname(directory)/'Formula/example_cli.rb'
      config = instance_double(
        Gembrew::Config,
        gem_name: 'example_cli',
        version: nil,
        output_path: output_path,
        description: nil,
        homepage: nil,
        license: nil,
        executable: nil,
        test_body: %(system bin/"example", "--version"),
      )
      spec = Gem::Specification.new do |gem|
        gem.name = 'example_cli'
        gem.version = '1.2.3'
        gem.summary = 'Example CLI'
        gem.homepage = 'https://example.com'
        gem.license = 'MIT'
        gem.executables = ['example']
      end
      resolution = Gembrew::Resolution.new(
        spec,
        'root-checksum',
        [Gembrew::Resource.new('dependency', '2.0.0', 'dependency-checksum')],
      )
      resolver = instance_double(Gembrew::Resolver)
      allow(resolver).to receive(:resolve).with('example_cli', nil).and_return(resolution)

      result = described_class.new(config: config, resolver: resolver).call
      formula = output_path.read

      expect(result).to eq output_path
      expect(formula).to include 'class ExampleCli < Formula'
      expect(formula).to include 'desc "Example CLI"'
      expect(formula).to include 'homepage "https://example.com"'
      expect(formula).to include 'sha256 "root-checksum"'
      expect(formula).to include 'resource "dependency" do'
      expect(formula).to include 'sha256 "dependency-checksum"'
      expect(formula).to include '(bin/"example").write_env_script'
      expect(formula).to include "  test do\n    system bin/\"example\", \"--version\"\n  end"
      expect(formula).to end_with "\n"
    end
  end
end
