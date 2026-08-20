require 'spec_helper'
require 'tmpdir'
require 'yaml'

describe Gembrew::Initializer do
  def initialize_project(directory, gem_name: 'example')
    described_class.new(gem_name, project_path: directory).call
  end

  it 'creates the tap repository structure' do
    Dir.mktmpdir do |directory|
      path = initialize_project(directory)
      config = YAML.safe_load_file "#{directory}/gembrew.yml"

      expect(path.to_s).to eq directory
      expect(File).to be_directory("#{directory}/Formula")
      expect(File).to be_directory("#{directory}/support")
      expect(File).to exist("#{directory}/support/compose.yaml")
      expect(config).to eq(
        'gem' => 'example',
        'output' => 'Formula/example.rb',
        'test' => %(system bin/"example", "--version"),
      )
      expect(File.read("#{directory}/gembrew.yml")).to end_with("\n")
    end
  end

  it 'creates a Homebrew Docker Compose environment' do
    Dir.mktmpdir do |directory|
      initialize_project(directory)
      compose = YAML.safe_load_file "#{directory}/support/compose.yaml"
      service = compose.fetch('services').fetch('brew')

      expect(service['image']).to eq 'homebrew/brew:main'
      expect(service['working_dir']).to eq '/work'
      expect(service['environment']['PS1']).to eq "\n\nbrew $ "
      expect(service['volumes']).to eq [
        '..:/work',
        '..:/home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/gembrew/homebrew-tap',
      ]
      expect(service['command']).to eq %w[bash --norc]
    end
  end

  it 'allows an existing Git metadata directory' do
    Dir.mktmpdir do |directory|
      Dir.mkdir "#{directory}/.git"

      initialize_project(directory)

      expect(File).to exist("#{directory}/gembrew.yml")
    end
  end

  it 'refuses to initialize a non-empty directory' do
    Dir.mktmpdir do |directory|
      File.write "#{directory}/README.md", ''
      File.write "#{directory}/LICENSE", ''

      expect { initialize_project(directory) }
        .to raise_error(
          Gembrew::Error,
          "Directory is not empty: #{directory} (found: LICENSE, README.md)",
        )
      expect(Dir.children(directory).sort).to eq %w[LICENSE README.md]
    end
  end
end
