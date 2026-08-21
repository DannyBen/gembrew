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
      expect(subject.version).to eq '1.4.0'
      expect(subject.source_type).to eq 'github'
      expect(subject.source_repo).to eq 'bashly-framework/bashly'
      expect(subject.source_tag).to eq 'v1.4.0'
      expect(subject.source_gemspec).to eq 'bashly.gemspec'
      expect(subject.output_path.to_s).to eq "#{fixture 'inline-test'}/Formula/bashly.rb"
      expect(subject.description).to eq 'Bashly CLI'
      expect(subject.dependencies).to eq ['bash']
      expect(subject.test_body).to eq %[system bin/"bashly", "--version"]
    end
  end

  context 'with an invalid GitHub repository' do
    let(:fixture_name) { 'external-test' }

    before do
      allow(YAML).to receive(:safe_load_file).and_return(
        'gem' => 'bashly',
        'version' => '1.4.0',
        'source' => {
          'type' => 'github',
          'repo' => 'https://github.com/bashly-framework/bashly',
        },
        'test' => 'assert true'
      )
    end

    it 'requires owner/repository form' do
      expect { subject }.to raise_error(Gembrew::Error, 'source.repo must be in owner/repository form')
    end
  end

  context 'without a version' do
    let(:fixture_name) { 'external-test' }

    before do
      allow(YAML).to receive(:safe_load_file).and_return(
        'gem' => 'bashly',
        'source' => { 'type' => 'gem' },
        'test' => 'assert true'
      )
    end

    it 'requires an explicit version' do
      expect { subject }.to raise_error(Gembrew::Error, 'version is required')
    end
  end

  context 'with invalid dependencies' do
    let(:fixture_name) { 'external-test' }

    before do
      allow(YAML).to receive(:safe_load_file).and_return(
        'gem' => 'bashly',
        'version' => '1.4.0',
        'source' => { 'type' => 'gem' },
        'dependencies' => 'bash',
        'test' => 'assert true'
      )
    end

    it 'requires a sequence of dependency names' do
      expect { subject }
        .to raise_error(Gembrew::Error, 'dependencies must be a sequence of names')
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
