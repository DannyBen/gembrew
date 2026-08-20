require 'spec_helper'
require 'fileutils'
require 'stringio'
require 'tmpdir'

describe Gembrew::ArchiveStore do
  let(:reporter) { instance_double(Gembrew::Reporter, archive: nil) }

  def build_archive(directory, name: 'example', version: '1.2.3')
    spec = Gem::Specification.new do |gem|
      gem.name = name
      gem.version = version
      gem.summary = 'Fixture gem'
      gem.authors = ['Fixture']
      gem.files = []
    end

    filename = nil
    Dir.chdir(directory) do
      capture_output { filename = Gem::Package.build(spec, true) }
    end
    Pathname(directory)/filename
  end

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original_stdout
  end

  it 'prefers an archive retained in a local RubyGems cache' do
    Dir.mktmpdir do |directory|
      gem_path = Pathname(directory)/'installed'
      cache_path = gem_path/'cache'
      cache_path.mkpath
      archive = build_archive(cache_path)
      store = described_class.new(cache_path: Pathname(directory)/'gembrew', reporter: reporter)
      allow(Gem).to receive(:path).and_return [gem_path.to_s]

      expect(store.fetch('example', '1.2.3', directory)).to eq archive
    end
  end

  it 'uses Gembrew cache when RubyGems has no retained archive' do
    Dir.mktmpdir do |directory|
      cache_path = Pathname(directory)/'gembrew'
      cache_path.mkpath
      archive = build_archive(cache_path)
      store = described_class.new(cache_path: cache_path, reporter: reporter)
      allow(Gem).to receive(:path).and_return []

      expect(store.fetch('example', '1.2.3', directory)).to eq archive
    end
  end

  it 'downloads and retains a missing archive' do
    Dir.mktmpdir do |directory|
      source_path = Pathname(directory)/'source'
      download_path = Pathname(directory)/'download'
      cache_path = Pathname(directory)/'cache'
      source_path.mkpath
      download_path.mkpath
      archive = build_archive(source_path)
      commands = []
      runner = lambda do |*command, chdir:|
        commands << [command, chdir]
        FileUtils.cp archive, chdir
      end
      store = described_class.new(
        cache_path: cache_path, reporter: reporter, command_runner: runner
      )
      allow(Gem).to receive(:path).and_return []

      result = store.fetch('example', '1.2.3', download_path)

      expect(commands).to eq [
        [%w[gem fetch example --platform ruby --version 1.2.3], download_path],
      ]
      expect(result).to eq cache_path/'example-1.2.3.gem'
      expect(result).to be_file
    end
  end

  it 'downloads the latest version when no version is requested' do
    Dir.mktmpdir do |directory|
      source_path = Pathname(directory)/'source'
      download_path = Pathname(directory)/'download'
      source_path.mkpath
      download_path.mkpath
      archive = build_archive(source_path)
      command = nil
      runner = lambda do |*args, chdir:|
        command = args
        FileUtils.cp archive, chdir
      end
      store = described_class.new(
        cache_path: Pathname(directory)/'cache', reporter: reporter, command_runner: runner
      )

      store.fetch 'example', nil, download_path

      expect(command).to eq %w[gem fetch example --platform ruby]
    end
  end

  it 'ignores a corrupt archive in Gembrew cache' do
    Dir.mktmpdir do |directory|
      source_path = Pathname(directory)/'source'
      download_path = Pathname(directory)/'download'
      cache_path = Pathname(directory)/'cache'
      source_path.mkpath
      download_path.mkpath
      cache_path.mkpath
      archive = build_archive(source_path)
      File.write cache_path/'example-1.2.3.gem', 'not a gem'
      runner = lambda do |*_, chdir:|
        FileUtils.cp archive, chdir
      end
      store = described_class.new(
        cache_path: cache_path, reporter: reporter, command_runner: runner
      )
      allow(Gem).to receive(:path).and_return []

      result = store.fetch 'example', '1.2.3', download_path

      expect(Gem::Package.new(result.to_s).spec.name).to eq 'example'
    end
  end

  describe 'command execution' do
    subject(:store) do
      described_class.new(cache_path: Pathname(directory)/'cache', reporter: reporter)
    end

    let(:directory) { Dir.mktmpdir }

    after { FileUtils.remove_entry directory }

    it 'returns output from a successful command' do
      output = store.send :run_command, 'ruby', '-e', 'print "done"', chdir: directory

      expect(output).to eq 'done'
    end

    it 'raises a Gembrew error when a command fails' do
      expect do
        store.send :run_command, 'ruby', '-e', 'abort "failed"', chdir: directory
      end.to raise_error(Gembrew::Error, "failed\n")
    end
  end
end
