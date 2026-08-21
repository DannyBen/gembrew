require 'spec_helper'
require 'tmpdir'

describe Gembrew::Initializer do
  subject { described_class.new('example', project_path: directory).call }

  let(:directory) { Pathname Dir.mktmpdir }

  after { directory.rmtree }

  it 'returns the project directory' do
    expect(subject).to eq directory
  end

  it 'creates the formula directory' do
    subject
    expect(directory/'Formula').to be_directory
  end

  it 'creates the gem configuration' do
    subject
    expect((directory/'gembrew/example.yml').read).to match_approval('initializer/gembrew.yml')
  end

  it 'creates the README' do
    subject
    expect((directory/'README.md').read).to match_approval('initializer/README.md')
  end

  it 'creates the test workflow' do
    subject
    workflow = (directory/'.github/workflows/test.yml').read
    expect(workflow).to match_approval('initializer/test.yml')
  end

  it 'tests and uninstalls each formula in the workflow' do
    subject
    workflow = (directory/'.github/workflows/test.yml').read
    expect(workflow).to match(
      /brew test "\$formula_name"\n\s+brew linkage --test "\$formula_name"\n\s+brew uninstall "\$formula_name"/
    )
  end

  it 'does not create a support directory' do
    subject
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

    it 'does not overwrite its test workflow' do
      workflow = directory/'.github/workflows/test.yml'
      workflow.dirname.mkpath
      workflow.write "name: Existing workflow\n"

      expect { subject }.not_to(change { workflow.read })
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

    it 'returns the project directory' do
      expect(subject).to eq directory
    end

    it 'creates the tap directories' do
      subject
      expect(directory/'Formula').to be_directory
      expect(directory/'gembrew').to be_directory
    end

    it 'creates the test workflow' do
      subject
      expect(directory/'.github/workflows/test.yml').to be_file
    end

    it 'does not add a gem configuration' do
      subject
      expect((directory/'gembrew').children).to be_empty
    end

    it 'creates generic installation instructions' do
      subject
      expect((directory/'README.md').read).to include('brew install FORMULA')
    end
  end
end
