require 'spec_helper'
require 'tmpdir'

describe Gembrew::Config do
  def write_config(directory, content)
    File.write "#{directory}/gembrew.yml", content
  end

  it 'loads values and resolves paths from the configuration directory' do
    Dir.mktmpdir do |directory|
      write_config directory, <<~YAML
        gem: example
        version: "1.2.3"
        output: Formula/example.rb
        desc: Example CLI
        test: |-
          system bin/"example", "--version"
      YAML

      config = described_class.new directory

      expect(config.gem_name).to eq 'example'
      expect(config.version).to eq '1.2.3'
      expect(config.output_path.to_s).to eq "#{directory}/Formula/example.rb"
      expect(config.description).to eq 'Example CLI'
      expect(config.test_body).to eq %(system bin/"example", "--version")
    end
  end

  it 'loads a test body relative to the configuration file' do
    Dir.mktmpdir do |directory|
      Dir.mkdir "#{directory}/support"
      File.write "#{directory}/support/test.rb", "assert true\n"
      write_config directory, <<~YAML
        gem: example
        output: Formula/example.rb
        test_from_file: support/test.rb
      YAML

      expect(described_class.new(directory).test_body).to eq "assert true\n"
    end
  end

  it 'requires a configuration file' do
    Dir.mktmpdir do |directory|
      expect { described_class.new directory }
        .to raise_error(Gembrew::Error, "Configuration does not exist: #{directory}/gembrew.yml")
    end
  end

  it 'requires a YAML mapping' do
    Dir.mktmpdir do |directory|
      write_config directory, "- example\n"

      expect { described_class.new directory }
        .to raise_error(Gembrew::Error, 'Configuration must be a YAML mapping')
    end
  end

  it 'reports invalid YAML' do
    Dir.mktmpdir do |directory|
      write_config directory, "gem: [\n"

      expect { described_class.new directory }
        .to raise_error(Gembrew::Error, /Invalid configuration:/)
    end
  end

  it 'rejects unknown keys' do
    Dir.mktmpdir do |directory|
      write_config directory, <<~YAML
        gem: example
        output: Formula/example.rb
        test: test
        unknown: true
      YAML

      expect { described_class.new directory }
        .to raise_error(Gembrew::Error, 'Unknown configuration keys: unknown')
    end
  end

  it 'requires gem and output values' do
    Dir.mktmpdir do |directory|
      write_config directory, "output: Formula/example.rb\ntest: test\n"

      expect { described_class.new directory }
        .to raise_error(Gembrew::Error, 'gem is required')
    end
  end

  it 'requires exactly one test source' do
    Dir.mktmpdir do |directory|
      write_config directory, "gem: example\noutput: Formula/example.rb\n"

      expect { described_class.new directory }
        .to raise_error(Gembrew::Error, 'Provide exactly one of test or test_from_file')
    end
  end

  it 'reports a missing external test file' do
    Dir.mktmpdir do |directory|
      write_config directory, <<~YAML
        gem: example
        output: Formula/example.rb
        test_from_file: missing.rb
      YAML

      expect { described_class.new(directory).test_body }
        .to raise_error(Gembrew::Error, "Test file does not exist: #{directory}/missing.rb")
    end
  end
end
