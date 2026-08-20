require 'spec_helper'
require 'tmpdir'

describe Gembrew::Initializer do
  subject { described_class.new('example', project_path: directory).call }

  let(:directory) { Pathname Dir.mktmpdir }

  after { directory.rmtree }

  it 'creates the tap repository structure' do
    expect(subject).to eq directory
    expect(directory/'Formula').to be_directory
    expect((directory/'gembrew/example.yml').read).to match_approval('initializer/gembrew.yml')
    expect((directory/'README.md').read).to match_approval('initializer/README.md')
    expect(directory/'support').not_to exist
  end

  context 'with an existing Git metadata directory' do
    before { (directory/'.git').mkpath }

    it 'allows initialization' do
      expect(subject).to eq directory
    end
  end

  context 'with an existing tap' do
    before do
      (directory/'Formula').mkpath
      (directory/'README.md').write ''
      (directory/'LICENSE').write ''
    end

    it 'adds Gembrew without disturbing existing files' do
      expect(subject).to eq directory
      expect(directory/'gembrew/example.yml').to be_file
      expect(directory/'README.md').to be_file
      expect(directory/'LICENSE').to be_file
    end

    it 'does not overwrite its README' do
      expect { subject }.not_to(change { (directory/'README.md').read })
    end
  end

  context 'with a non-tap directory' do
    before { (directory/'README.md').write '' }

    it 'refuses to initialize the directory' do
      expect { subject }.to raise_error(Gembrew::Error, %r{Formula/ does not exist})
    end
  end

  context 'without a gem name' do
    subject { described_class.new(project_path: directory).call }

    it 'initializes an empty tap' do
      expect(subject).to eq directory
      expect(directory/'Formula').to be_directory
      expect(directory/'gembrew').to be_directory
      expect((directory/'gembrew').children).to be_empty
      expect((directory/'README.md').read).to include('brew install FORMULA')
    end
  end
end
