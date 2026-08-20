require 'spec_helper'

describe Gembrew::Config do
  subject do
    project_path = Pathname fixture(fixture_name)
    described_class.new project_path/'gembrew.yml', project_path: project_path
  end

  context 'with an inline test' do
    let(:fixture_name) { 'inline-test' }

    it 'loads values and resolves paths from the configuration directory' do
      expect(subject.gem_name).to eq 'bashly'
      expect(subject.version).to be_nil
      expect(subject.repository).to eq 'https://github.com/bashly-framework/homebrew-tap'
      expect(subject.output_path.to_s).to eq "#{fixture 'inline-test'}/Formula/bashly.rb"
      expect(subject.description).to eq 'Bashly CLI'
      expect(subject.test_body).to eq %[system bin/"bashly", "--version"]
    end
  end

  context 'with an HTTPS repository URL' do
    let(:fixture_name) { 'external-test' }

    before do
      allow(YAML).to receive(:safe_load_file).and_return(
        'gem' => 'bashly',
        'repository' => 'https://git.example.com/tools/homebrew-tap',
        'test' => 'assert true'
      )
    end

    it 'uses the URL unchanged' do
      expect(subject.repository).to eq 'https://git.example.com/tools/homebrew-tap'
    end
  end

  context 'with an external test' do
    let(:fixture_name) { 'external-test' }

    it 'loads a test body relative to the tap root' do
      expect(subject.test_body).to eq "assert true\n"
    end
  end

  context 'without a configuration file' do
    let(:fixture_name) { 'missing-config' }

    it 'requires a configuration file' do
      expect { subject }.to raise_error(
        Gembrew::Error,
        "Configuration does not exist: #{fixture fixture_name}/gembrew.yml"
      )
    end
  end

  context 'with a YAML sequence' do
    let(:fixture_name) { 'yaml-sequence' }

    it 'requires a YAML mapping' do
      expect { subject }
        .to raise_error(Gembrew::Error, 'Configuration must be a YAML mapping')
    end
  end

  context 'with invalid YAML' do
    let(:fixture_name) { 'invalid-yaml' }

    it 'reports invalid YAML' do
      expect { subject }
        .to raise_error(Gembrew::Error, /Invalid configuration:/)
    end
  end

  context 'with an unknown key' do
    let(:fixture_name) { 'unknown-key' }

    it 'rejects unknown keys' do
      expect { subject }
        .to raise_error(Gembrew::Error, 'Unknown configuration keys: unknown')
    end
  end

  context 'without a gem value' do
    let(:fixture_name) { 'missing-gem' }

    it 'requires a gem value' do
      expect { subject }
        .to raise_error(Gembrew::Error, 'gem is required')
    end
  end

  context 'without a test source' do
    let(:fixture_name) { 'missing-test-source' }

    it 'requires exactly one test source' do
      expect { subject }
        .to raise_error(Gembrew::Error, 'Provide exactly one of test or test_from_file')
    end
  end

  context 'with a missing external test file' do
    let(:fixture_name) { 'missing-external-test' }

    it 'reports a missing external test file' do
      expect { subject.test_body }.to raise_error(
        Gembrew::Error,
        "Test file does not exist: #{fixture fixture_name}/missing.rb"
      )
    end
  end

  describe '.all' do
    it 'loads every configuration in filename order' do
      configs = described_class.all fixture('discovery')
      expect(configs.map(&:name)).to eq %w[bashly completely]
    end

    it 'requires at least one configuration' do
      expect { described_class.all fixture('missing-config') }.to raise_error(
        Gembrew::Error,
        "No gem configurations found in #{fixture 'missing-config'}/gembrew"
      )
    end
  end

  describe '.find' do
    it 'loads one named configuration' do
      config = described_class.find 'bashly', fixture('discovery')
      expect(config.gem_name).to eq 'bashly'
    end
  end
end
