require 'spec_helper'
require 'tmpdir'

describe Gembrew::Config do
  subject { described_class.new config_path, project_path: project_path }

  let(:project_path) { Pathname fixture('directory-config') }
  let(:config_path) { project_path/'gembrew/bashly/formula.yml' }

  it 'loads the gem identity' do
    expect(subject.gem_name).to eq 'bashly'
    expect(subject.version).to eq '1.4.0'
    expect(subject.name).to eq 'bashly'
  end

  it 'loads the GitHub source' do
    expect(subject.source_type).to eq 'github'
    expect(subject.source_repo).to eq 'bashly-framework/bashly'
    expect(subject.source_tag).to eq 'v1.4.0'
    expect(subject.source_gemspec).to eq 'bashly.gemspec'
  end

  it 'resolves the output path from the project directory' do
    expect(subject.output_path.to_s).to eq "#{project_path}/Formula/bashly.rb"
  end

  it 'loads metadata overrides' do
    expect(subject.description).to eq 'Bashly CLI'
  end

  it 'parses platform-specific dependencies' do
    expect(subject.dependencies).to eq [
      Gembrew::Config::Dependency.new(name: 'bash', tags: [:macos_only]),
      Gembrew::Config::Dependency.new(name: 'libffi', tags: [:system_on_macos]),
    ]
  end

  it 'loads optional Ruby hooks beside formula.yml' do
    expect(subject.install_extra_body).to eq <<~RUBY
      rm libexec.glob("extensions/*/*/*/mkmf.log")
      deuniversalize_machos if OS.mac?
    RUBY
    expect(subject.test_body).to eq %[system bin/"bashly", "--version"\n]
  end

  context 'without optional Ruby hooks' do
    let(:project_path) { Pathname fixture('discovery') }
    let(:config_path) { project_path/'gembrew/bashly/formula.yml' }

    it 'returns nil hook bodies' do
      expect(subject.install_extra_body).to be_nil
      expect(subject.test_body).to be_nil
    end
  end

  context 'with an empty test hook' do
    let(:project_path) { Pathname Dir.mktmpdir }
    let(:config_path) { project_path/'gembrew/bashly/formula.yml' }

    before do
      config_path.dirname.mkpath
      config_path.write <<~YAML
        gem: bashly
        version: "1.4.0"
        source:
          type: rubygems
      YAML
      (config_path.dirname/'test.rb').write "\n"
    end

    after { project_path.rmtree }

    it 'uses the generated default test' do
      expect(subject.test_body).to be_nil
    end
  end

  context 'with invalid data' do
    let(:project_path) { Pathname Dir.mktmpdir }
    let(:directory) { project_path/'gembrew/bashly' }

    before { directory.mkpath }
    after { project_path.rmtree }

    def write_config(data)
      (directory/'formula.yml').write YAML.dump(data)
    end

    it 'requires an explicit version' do
      write_config 'gem' => 'bashly', 'source' => { 'type' => 'rubygems' }
      expect { subject }.to raise_error(Gembrew::Error, 'version is required')
    end

    it 'requires GitHub repositories in owner/repository form' do
      write_config(
        'gem' => 'bashly', 'version' => '1.4.0',
        'source' => { 'type' => 'github', 'repo' => 'https://github.com/bashly-framework/bashly' }
      )
      expect { subject }.to raise_error(Gembrew::Error, 'source.repo must be in owner/repository form')
    end

    it 'requires a supported source type' do
      write_config(
        'gem' => 'bashly', 'version' => '1.4.0', 'source' => { 'type' => 'archive' }
      )
      expect { subject }.to raise_error(Gembrew::Error, 'source.type must be github or rubygems')
    end

    it 'keeps the GitHub gemspec inside the source archive' do
      write_config(
        'gem' => 'bashly', 'version' => '1.4.0',
        'source' => { 'type' => 'github', 'repo' => 'bashly-framework/bashly', 'gemspec' => '../bashly.gemspec' }
      )
      expect { subject }.to raise_error(
        Gembrew::Error,
        'source.gemspec must be a relative path within the archive'
      )
    end

    it 'rejects unknown keys from the former inline test format' do
      write_config(
        'gem' => 'bashly', 'version' => '1.4.0', 'source' => { 'type' => 'rubygems' },
        'test' => 'assert true'
      )
      expect { subject }.to raise_error(Gembrew::Error, 'Unknown configuration keys: test')
    end

    it 'requires dependencies to be a sequence' do
      write_config(
        'gem' => 'bashly', 'version' => '1.4.0', 'source' => { 'type' => 'rubygems' },
        'dependencies' => 'bash'
      )
      expect { subject }.to raise_error(Gembrew::Error, 'dependencies must be a sequence')
    end

    it 'rejects unknown dependency tags' do
      write_config(
        'gem' => 'bashly', 'version' => '1.4.0', 'source' => { 'type' => 'rubygems' },
        'dependencies' => ['libffi :native']
      )
      expect { subject }.to raise_error(Gembrew::Error, 'unknown dependency tag: ":native"')
    end

    it 'requires a dependency name before its tags' do
      write_config(
        'gem' => 'bashly', 'version' => '1.4.0', 'source' => { 'type' => 'rubygems' },
        'dependencies' => [':macos_only']
      )
      expect { subject }.to raise_error(Gembrew::Error, 'dependency name must be a non-empty string')
    end

    it 'reports malformed YAML' do
      (directory/'formula.yml').write "gem: [\n"
      expect { subject }.to raise_error(Gembrew::Error, /Invalid configuration:/)
    end
  end

  context 'without a configuration file' do
    let(:project_path) { Pathname fixture('missing-config') }
    let(:config_path) { project_path/'gembrew/bashly/formula.yml' }

    it 'requires formula.yml' do
      expect { subject }.to raise_error(Gembrew::Error, "Configuration does not exist: #{config_path}")
    end
  end

  describe '.all' do
    it 'loads every configuration directory in name order' do
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
    it 'loads one named configuration directory' do
      config = described_class.find 'bashly', fixture('discovery')
      expect(config.gem_name).to eq 'bashly'
    end
  end
end
