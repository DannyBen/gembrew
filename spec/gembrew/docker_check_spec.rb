require 'spec_helper'

describe Gembrew::DockerCheck do
  subject { described_class.new runner: runner }

  let(:runner) { double call: true }
  let(:script_matcher) do
    a_string_including(
      "printf '\\n\\033[1;34m==> gembrew: %s\\033[0m\\n'",
      'caption "styling $formula"', 'brew audit --new --online "$formula"',
      'brew install --build-from-source "$formula"', 'brew test "$formula"',
      'caption "checking linkage for $formula"', 'brew linkage --test "$formula"'
    )
  end

  it 'runs the complete check sequence with captions' do
    arguments = []
    allow(runner).to receive(:call) { |*args| arguments.replace args }
    expect(subject.call('example')).to be true
    expect(arguments).to match ['bash', '-euc', script_matcher]

    script = arguments.last
    expect(script.index('brew test "$formula"')).to be < script.index('brew linkage --test "$formula"')
  end

  context 'when the check fails' do
    let(:runner) { double call: false }

    it 'reports failed checks' do
      expect { subject.call('example') }.to raise_error(Gembrew::Error, 'Homebrew checks failed')
    end
  end
end
