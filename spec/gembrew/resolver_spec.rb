require 'spec_helper'
require 'digest'
require 'fileutils'
require 'stringio'
require 'tmpdir'

describe Gembrew::Resolver do
  let(:reporter) do
    instance_double(Gembrew::Reporter, resolving: nil, collecting: nil, archive: nil)
  end

  def root_spec
    Gem::Specification.new do |gem|
      gem.name = 'root'
      gem.version = '1.0.0'
    end
  end

  def build_archive(directory, name:, version:)
    spec = Gem::Specification.new do |gem|
      gem.name = name
      gem.version = version
      gem.summary = 'Fixture gem'
      gem.authors = ['Fixture']
      gem.files = []
    end

    filename = nil
    original_stdout = $stdout
    $stdout = StringIO.new
    Dir.chdir(directory) { filename = Gem::Package.build(spec, true) }
    Pathname(directory)/filename
  ensure
    $stdout = original_stdout
  end

  it 'resolves archives and calculates their checksums' do
    Dir.mktmpdir do |directory|
      fixture_path = Pathname(directory)/'fixtures'
      fixture_path.mkpath
      root_archive = build_archive fixture_path, name: 'root', version: '1.0.0'
      dependency_archive = build_archive fixture_path, name: 'dependency', version: '2.0.0'
      archive_store = instance_double(Gembrew::ArchiveStore)
      allow(archive_store).to receive(:fetch) do |name, _version, _path, **_progress|
        name == 'root' ? root_archive : dependency_archive
      end
      runner = lambda do |*command, chdir:, env:|
        Pathname(command.fetch(command.index('--lockfile') + 1)).write <<~LOCK
          GEM
            remote: https://rubygems.org/
            specs:
              dependency (2.0.0)
              root (1.0.0)
                dependency

          PLATFORMS
            ruby

          DEPENDENCIES
            root (= 1.0.0)

          BUNDLED WITH
             4.0.17
        LOCK
      end
      resolver = described_class.new(
        cache_root: Pathname(directory)/'cache',
        reporter: reporter,
        command_runner: runner,
        archive_store: archive_store,
      )

      resolution = resolver.resolve 'root', '1.0.0'

      expect(resolution.spec.name).to eq 'root'
      expect(resolution.sha256).to eq Digest::SHA256.file(root_archive).hexdigest
      expect(resolution.resources).to eq [
        Gembrew::Resource.new(
          'dependency',
          '2.0.0',
          Digest::SHA256.file(dependency_archive).hexdigest,
        ),
      ]
      expect(reporter).to have_received(:collecting).with(1)
      expect(archive_store).to have_received(:fetch)
        .with('dependency', Gem::Version.new('2.0.0'), anything, index: 1, total: 1)
    end
  end

  it 'selects generic Ruby variants from a multi-platform lockfile' do
    Dir.mktmpdir do |directory|
      lockfile = Pathname(directory)/'Gemfile.lock'
      lockfile.write <<~LOCK
        GEM
          remote: https://rubygems.org/
          specs:
            dependency (1.0.0)
            dependency (1.0.0-x86_64-linux)
            root (1.0.0)
              dependency

        PLATFORMS
          ruby
          x86_64-linux

        DEPENDENCIES
          root (= 1.0.0)

        BUNDLED WITH
           4.0.17
      LOCK
      resolver = described_class.new(
        cache_root: Pathname(directory)/'cache',
        reporter: reporter,
        archive_store: instance_double(Gembrew::ArchiveStore),
      )

      specs = resolver.send :dependency_specs, lockfile, root_spec

      expect(specs.length).to eq 1
      expect(specs.first.name).to eq 'dependency'
      expect(specs.first.platform).to eq Gem::Platform::RUBY
    end
  end

  it 'locks with the generic Ruby platform forced' do
    Dir.mktmpdir do |directory|
      temporary = Pathname(directory)/'work'
      temporary.mkpath
      invocation = nil
      runner = lambda do |*command, chdir:, env:|
        invocation = { command: command, chdir: chdir, env: env }
        Pathname(command.fetch(command.index('--lockfile') + 1)).write "lock\n"
      end
      resolver = described_class.new(
        cache_root: Pathname(directory)/'cache',
        reporter: reporter,
        command_runner: runner,
        archive_store: instance_double(Gembrew::ArchiveStore),
      )

      lockfile = resolver.send :lock, root_spec, temporary

      expect(invocation[:command]).to include 'bundle', 'lock', '--add-platform', 'ruby'
      expect(invocation[:chdir]).to eq temporary
      expect(invocation[:env]).to eq(
        'BUNDLE_FORCE_RUBY_PLATFORM' => 'true',
        'BUNDLE_GEMFILE' => temporary.join('Gemfile').to_s,
      )
      expect(lockfile).to be_file
    end
  end

  it 'uses the XDG cache directory by default' do
    Dir.mktmpdir do |directory|
      original = ENV['XDG_CACHE_HOME']
      ENV['XDG_CACHE_HOME'] = directory

      resolver = described_class.new(
        reporter: reporter,
        archive_store: instance_double(Gembrew::ArchiveStore),
      )

      expect(resolver.cache_root).to eq Pathname(directory)/'gembrew'
    ensure
      ENV['XDG_CACHE_HOME'] = original
    end
  end

  describe 'command execution' do
    subject(:resolver) do
      described_class.new(
        cache_root: Pathname(directory)/'cache',
        reporter: reporter,
        archive_store: instance_double(Gembrew::ArchiveStore),
      )
    end

    let(:directory) { Dir.mktmpdir }

    after { FileUtils.remove_entry directory }

    it 'returns output from a successful command' do
      output = resolver.send(
        :run_command, 'ruby', '-e', 'print ENV.fetch("VALUE")',
        chdir: directory, env: { 'VALUE' => 'done' }
      )

      expect(output).to eq 'done'
    end

    it 'raises a Gembrew error when a command fails' do
      expect do
        resolver.send :run_command, 'ruby', '-e', 'abort "failed"', chdir: directory
      end.to raise_error(Gembrew::Error, "failed\n")
    end
  end
end
