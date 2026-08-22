require 'spec_helper'

describe Gembrew::DockerRunner do
  subject { described_class.new project_path: '/tap', command_runner: command_runner }

  let(:command_runner) { double call: true }
  let(:container_name) { "gembrew-#{Process.pid}" }
  let(:expected_command) do
    [
      'docker', 'run', '--rm', '--init', '--name', container_name,
      '--env', 'HOMEBREW_NO_AUTO_UPDATE=1',
      '--env', 'HOMEBREW_NO_INSTALL_CLEANUP=1',
      '--env', 'HOMEBREW_NO_INSTALL_FROM_API=1',
      '--workdir', '/work', '--volume', '/tap:/work',
      '--volume', "/tap:#{described_class::TAP_PATH}",
      described_class::IMAGE, 'command'
    ]
  end

  it 'runs a disposable Homebrew container with the tap mounted' do
    expect(command_runner).to receive(:call).with(
      *expected_command, chdir: Pathname('/tap')
    )
    expect(subject.call('command')).to be true
  end

  it 'allocates a terminal for interactive commands' do
    arguments = []
    allow(command_runner).to receive(:call) { |*args| arguments.replace args }
    subject.call 'bash', interactive: true

    expect(arguments).to include '-it', 'PS1=\n\ngembrew $ '
  end

  it 'runs a pristine container without mounting the local tap' do
    arguments = []
    allow(command_runner).to receive(:call) { |*args| arguments.replace args }
    subject.call 'bash', interactive: true, pristine: true

    expect(arguments).to include '--pull=always', '-it', 'PS1=\n\nhomebrew $ '
    expect(arguments).not_to include '--workdir', '--volume'
  end

  it 'leaves the stock Homebrew environment unchanged in a pristine container' do
    arguments = []
    allow(command_runner).to receive(:call) { |*args| arguments.replace args }
    subject.call 'bash', pristine: true

    expect(arguments).not_to include(
      'HOMEBREW_NO_AUTO_UPDATE=1',
      'HOMEBREW_NO_INSTALL_CLEANUP=1',
      'HOMEBREW_NO_INSTALL_FROM_API=1'
    )
  end

  it 'streams command output through the system process' do
    runner = described_class.allocate
    allow(runner).to receive(:system).with('command', chdir: '/tap').and_return true

    expect(runner.send(:run_command, 'command', chdir: Pathname('/tap'))).to be true
  end

  it 'force-removes a failed container' do
    runner = described_class.allocate
    command = %w[docker run --name gembrew-test command]
    allow(runner).to receive(:system).with(*command, chdir: '/tap').and_return false
    expect(runner).to receive(:system).with(
      *%w[docker rm --force gembrew-test], out: File::NULL, err: File::NULL
    )

    expect(runner.send(:run_command, *command, chdir: Pathname('/tap'))).to be false
  end

  it 'force-removes an interrupted container and preserves the interrupt' do
    runner = described_class.allocate
    command = %w[docker run --name gembrew-test command]
    allow(runner).to receive(:system).with(*command, chdir: '/tap').and_raise Interrupt
    expect(runner).to receive(:system).with(
      *%w[docker rm --force gembrew-test], out: File::NULL, err: File::NULL
    )

    expect { runner.send(:run_command, *command, chdir: Pathname('/tap')) }.to raise_error Interrupt
  end
end
