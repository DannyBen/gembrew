require 'spec_helper'
require 'tmpdir'

describe Gembrew::GithubArchiveStore do
  let(:directory) { Pathname Dir.mktmpdir }
  let(:reporter) { instance_double Gembrew::Reporter, archive: nil }
  let(:commands) { [] }
  let(:runner) do
    lambda do |*command, chdir:|
      commands << [command, chdir]
      Pathname(command[command.index('--output') + 1]).write 'archive' if command.first == 'curl'
    end
  end
  let(:store) do
    described_class.new cache_path: directory/'cache', reporter: reporter, command_runner: runner
  end

  after { directory.rmtree }

  it 'downloads and caches the vVERSION archive' do
    path = store.fetch 'owner/project', 'v1.2.3'

    expect(path).to be_file
    expect(commands.first.first).to include(
      'https://github.com/owner/project/archive/refs/tags/v1.2.3.tar.gz'
    )
    expect(store.fetch('owner/project', 'v1.2.3')).to eq path
    expect(commands.length).to eq 1
  end
end
