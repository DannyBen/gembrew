require 'spec_helper'
require 'fileutils'
require 'tmpdir'

describe Gembrew::ArchiveStore do
  let(:reporter) { instance_double(Gembrew::Reporter, archive: nil) }

  context 'with a cached archive' do
    subject { described_class.new cache_path: directory/'gembrew', reporter: reporter }

    let(:directory) { Pathname Dir.mktmpdir }
    let(:gem_paths) { [] }
    let!(:archive) do
      archive_path.mkpath
      build_archive archive_path
    end

    before { allow(Gem).to receive(:path).and_return gem_paths }
    after { directory.rmtree }

    context 'with an archive in the RubyGems cache' do
      let(:archive_path) { directory/'installed/cache' }
      let(:gem_paths) { [(directory/'installed').to_s] }

      it 'prefers the RubyGems archive' do
        expect(subject.fetch('example', '1.2.3', directory)).to eq archive
      end
    end

    context 'with an archive in the Gembrew cache' do
      let(:archive_path) { directory/'gembrew' }

      it 'uses the Gembrew archive' do
        expect(subject.fetch('example', '1.2.3', directory)).to eq archive
      end
    end
  end

  context 'when downloading an archive' do
    subject { store.fetch 'example', version, download_path }

    let(:store) do
      described_class.new cache_path: directory/'cache', reporter: reporter, command_runner: runner
    end
    let(:directory) { Pathname Dir.mktmpdir }
    let(:download_path) { directory/'download' }
    let(:version) { '1.2.3' }
    let(:commands) { [] }
    let(:runner) do
      lambda do |*command, chdir:|
        commands << [command, chdir]
        FileUtils.cp archive, chdir
      end
    end
    let(:archive) { build_archive directory/'source' }

    before do
      (directory/'source').mkpath
      download_path.mkpath
      allow(Gem).to receive(:path).and_return []
    end

    after { directory.rmtree }

    it 'downloads and retains a missing archive' do
      expect(subject).to eq directory/'cache/example-1.2.3.gem'
      expect(subject).to be_file
      expect(commands).to eq [
        [%w[gem fetch example --platform ruby --version 1.2.3], download_path],
      ]
    end

    context 'without a requested version' do
      let(:version) { nil }

      it 'downloads the latest version' do
        expect(subject).to be_file
        expect(commands.first.first).to eq %w[gem fetch example --platform ruby]
      end
    end

    context 'with a corrupt archive in the Gembrew cache' do
      before do
        (directory/'cache').mkpath
        (directory/'cache/example-1.2.3.gem').write 'not a gem'
      end

      it 'downloads a valid replacement' do
        expect(Gem::Package.new(subject.to_s).spec.name).to eq 'example'
      end
    end
  end

  describe 'command execution' do
    subject do
      described_class.new(cache_path: Pathname(directory)/'cache', reporter: reporter)
    end

    let(:directory) { Dir.mktmpdir }

    after { FileUtils.remove_entry directory }

    it 'returns output from a successful command' do
      output = subject.send :run_command, 'ruby', '-e', 'print "done"', chdir: directory

      expect(output).to eq 'done'
    end

    it 'raises a Gembrew error when a command fails' do
      expect do
        subject.send :run_command, 'ruby', '-e', 'abort "failed"', chdir: directory
      end.to raise_error(Gembrew::Error, "failed\n")
    end
  end
end
