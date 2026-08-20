require 'spec_helper'
require 'tmpdir'

describe Gembrew::Initializer do
  subject { described_class.new('example', project_path: directory).call }

  let(:directory) { Pathname Dir.mktmpdir }

  after { directory.rmtree }

  it 'creates the tap repository structure' do
    expect(subject).to eq directory
    expect(directory/'Formula').to be_directory
    expect((directory/'gembrew.yml').read).to match_approval('initializer/gembrew.yml')
    expect((directory/'support/compose.yaml').read).to match_approval('initializer/compose.yaml')
  end

  context 'with an existing Git metadata directory' do
    before { (directory/'.git').mkpath }

    it 'allows initialization' do
      expect(subject).to eq directory
    end
  end

  context 'with other existing files' do
    before do
      (directory/'README.md').write ''
      (directory/'LICENSE').write ''
    end

    it 'refuses to initialize the directory' do
      expect { subject }.to raise_error(
        Gembrew::Error,
        "Directory is not empty: #{directory} (found: LICENSE, README.md)"
      )
      expect(directory.children.map { |path| path.basename.to_s }.sort).to eq %w[LICENSE README.md]
    end
  end
end
