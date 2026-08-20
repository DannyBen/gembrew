require 'spec_helper'
require 'tmpdir'

describe Gembrew::Adder do
  subject { described_class.new('example', project_path: directory) }

  let(:directory) { Pathname Dir.mktmpdir }

  after { directory.rmtree }

  it 'adds a gem configuration to an existing tap' do
    (directory/'Formula').mkpath
    expect(subject.call).to eq directory/'gembrew/example.yml'
    expect((directory/'gembrew/example.yml').read).to match_approval('initializer/gembrew.yml')
  end

  it 'requires an existing tap' do
    expect { subject.call }.to raise_error(Gembrew::Error, %r{Formula/ does not exist})
  end

  it 'does not overwrite an existing configuration' do
    (directory/'Formula').mkpath
    subject.call
    expect { subject.call }.to raise_error(Gembrew::Error, /already exists/)
  end

  it 'rejects names that could escape the configuration directory' do
    (directory/'Formula').mkpath
    adder = described_class.new('../example', project_path: directory)
    expect { adder.call }.to raise_error(Gembrew::Error, /Invalid gem name/)
  end
end
