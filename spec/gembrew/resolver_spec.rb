require 'spec_helper'
require 'digest'
require 'fileutils'
require 'tmpdir'

describe Gembrew::Resolver do
  let(:reporter) do
    instance_double Gembrew::Reporter, resolving: nil, collecting: nil, archive: nil
  end

  context 'when resolving a gem' do
    subject { resolver.resolve 'root', '1.0.0', source: { 'type' => 'gem' } }

    let(:directory) { Pathname Dir.mktmpdir }
    let(:archives) do
      archive_path = directory/'fixtures'
      archive_path.mkpath
      {
        root:       build_archive(archive_path, name: 'root', version: '1.0.0'),
        dependency: build_archive(archive_path, name: 'dependency', version: '2.0.0'),
      }
    end
    let(:archive_store) { instance_double Gembrew::ArchiveStore }
    let(:runner) do
      lambda do |*command, **|
        FileUtils.cp fixture('resolver/basic.lock'), command.fetch(command.index('--lockfile') + 1)
      end
    end
    let(:resolver) do
      described_class.new(
        cache_root: directory/'cache', reporter: reporter,
        command_runner: runner, archive_store: archive_store
      )
    end

    before do
      allow(archive_store).to receive(:fetch) do |name, _version, _path, **_progress|
        archives.fetch name.to_sym
      end
    end

    after { directory.rmtree }

    it 'calculates checksums for the gem and its resources' do
      expect(archive_store).to receive(:fetch)
        .with('dependency', Gem::Version.new('2.0.0'), anything, index: 1, total: 1)
      expect(reporter).to receive(:collecting).with(1)
      expect(subject.spec.name).to eq 'root'
      expect(subject.sha256).to eq Digest::SHA256.file(archives[:root]).hexdigest
      expect(subject.resources).to eq [Gembrew::Resource.new(
        'dependency', '2.0.0', Digest::SHA256.file(archives[:dependency]).hexdigest
      )]
    end
  end

  context 'with a GitHub source archive' do
    let(:directory) { Pathname Dir.mktmpdir }
    let(:archive) { directory/'bashly.tar.gz' }
    let(:source) { directory/'source' }
    let(:github_store) { instance_double Gembrew::GithubArchiveStore }
    let(:resolver) do
      described_class.new(
        cache_root: directory/'cache', reporter: reporter,
        archive_store: instance_double(Gembrew::ArchiveStore),
        github_archive_store: github_store
      )
    end

    before do
      archive.write 'archive'
      project = source/'bashly-1.4.0'
      project.mkpath
      (project/'bashly.gemspec').write <<~RUBY
        Gem::Specification.new do |gem|
          gem.name = 'bashly'
          gem.version = '1.4.0'
          gem.summary = 'Bashly'
          gem.authors = ['Fixture']
        end
      RUBY
      allow(github_store).to receive(:fetch).with('bashly-framework/bashly', 'v1.4.0').and_return archive
      allow(github_store).to receive(:extract).with(archive, anything).and_return source
    end

    after { directory.rmtree }

    it 'loads GEMNAME.gemspec from the configured repository archive' do
      root_archive, spec = resolver.send(
        :root_source, 'bashly', '1.4.0',
        { 'type' => 'github', 'repo' => 'bashly-framework/bashly' }, directory/'work'
      )

      expect(root_archive).to eq archive
      expect(spec.name).to eq 'bashly'
      expect(spec.version.to_s).to eq '1.4.0'
    end

    it 'reports the expected gemspec path when it is missing' do
      (source/'bashly-1.4.0/bashly.gemspec').delete

      expect do
        resolver.send(
          :root_source, 'bashly', '1.4.0',
          { 'type' => 'github', 'repo' => 'bashly-framework/bashly' }, directory/'work'
        )
      end.to raise_error(Gembrew::Error, 'Gemspec not found in GitHub archive: bashly.gemspec')
    end
  end

  context 'with a multi-platform lockfile' do
    subject { resolver.send :dependency_specs, lockfile, root_spec }

    let(:lockfile) { Pathname fixture('resolver/multi-platform.lock') }
    let(:root_spec) do
      Gem::Specification.new do |gem|
        gem.name = 'root'
        gem.version = '1.0.0'
      end
    end
    let(:resolver) do
      described_class.new reporter: reporter, archive_store: instance_double(Gembrew::ArchiveStore)
    end

    it 'selects the generic Ruby variant' do
      expect(subject.length).to eq 1
      expect(subject.first.name).to eq 'dependency'
      expect(subject.first.platform).to eq Gem::Platform::RUBY
    end
  end

  context 'when locking dependencies' do
    subject { resolver.send :lock, root_spec, temporary }

    let(:directory) { Pathname Dir.mktmpdir }
    let(:temporary) { directory/'work' }
    let(:invocation) { {} }
    let(:runner) do
      lambda do |*command, chdir:, env:|
        invocation.replace command: command, chdir: chdir, env: env
        Pathname(command.fetch(command.index('--lockfile') + 1)).write "lock\n"
      end
    end
    let(:resolver) do
      described_class.new(
        cache_root: directory/'cache', reporter: reporter,
        command_runner: runner, archive_store: instance_double(Gembrew::ArchiveStore)
      )
    end
    let(:root_spec) do
      Gem::Specification.new do |gem|
        gem.name = 'root'
        gem.version = '1.0.0'
        gem.add_runtime_dependency 'dependency', '>= 2.0', '< 3.0'
      end
    end

    before { temporary.mkpath }
    after { directory.rmtree }

    it 'forces the generic Ruby platform' do
      expect(subject).to be_file
      expect(invocation[:command]).to include 'bundle', 'lock', '--add-platform', 'ruby'
      expect(invocation[:chdir]).to eq temporary
      expect(invocation[:env]).to eq(
        'BUNDLE_FORCE_RUBY_PLATFORM' => 'true',
        'BUNDLE_GEMFILE'             => (temporary/'Gemfile').to_s
      )
      expect((temporary/'Gemfile').read).to include(
        'gem "dependency", ">= 2.0", "< 3.0"'
      )
      expect((temporary/'Gemfile').read).not_to include 'gem "root"'
    end
  end

  context 'with an XDG cache directory' do
    subject do
      described_class.new reporter: reporter, archive_store: instance_double(Gembrew::ArchiveStore)
    end

    let(:directory) { Pathname Dir.mktmpdir }

    around do |example|
      original = ENV['XDG_CACHE_HOME']
      ENV['XDG_CACHE_HOME'] = directory.to_s
      example.run
    ensure
      ENV['XDG_CACHE_HOME'] = original
      directory.rmtree
    end

    it 'uses it as the default cache root' do
      expect(subject.cache_root).to eq directory/'gembrew'
    end
  end

  describe 'command execution' do
    subject do
      described_class.new(
        cache_root: directory/'cache', reporter: reporter,
        archive_store: instance_double(Gembrew::ArchiveStore)
      )
    end

    let(:directory) { Pathname Dir.mktmpdir }

    after { directory.rmtree }

    it 'returns output from a successful command' do
      expect(subject.send(
        :run_command, 'ruby', '-e', 'print ENV.fetch("VALUE")',
        chdir: directory, env: { 'VALUE' => 'done' }
      )).to eq 'done'
    end

    it 'raises a Gembrew error when a command fails' do
      expect do
        subject.send :run_command, 'ruby', '-e', 'abort "failed"', chdir: directory
      end.to raise_error(Gembrew::Error, "failed\n")
    end
  end
end
