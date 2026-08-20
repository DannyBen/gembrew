require 'spec_helper'

describe Gembrew::Reporter do
  subject { described_class.new }

  it 'aligns counters to totals with three digits' do
    expect(subject).to receive(:say)
      .with('  1/123  g`RubyGems cache`  nb`first` 1.0.0')
    expect(subject).to receive(:say)
      .with('100/123  g`Gembrew cache `  nb`second` 2.0.0')

    subject.archive :rubygems_cache, 'first', '1.0.0', index: 1, total: 123
    subject.archive :gembrew_cache, 'second', '2.0.0', index: 100, total: 123
  end

  it 'uses yellow for downloads and bold for gem names' do
    expect(subject).to receive(:say)
      .with(' 9/26  y`Downloading   `  nb`example` 1.2.3')

    subject.archive :downloading, 'example', '1.2.3', index: 9, total: 26
  end

  it 'omits the counter for the root archive' do
    expect(subject).to receive(:say).with('y`Downloading   `  nb`example`')

    subject.archive :downloading, 'example', nil
  end

  it 'reports resolution phases' do
    expect(subject).to receive(:say)
      .with('Resolving dependencies for nb`example` 1.2.3...')
    expect(subject).to receive(:say)
      .with('Collecting nb`123` resources...')

    subject.resolving 'example', '1.2.3'
    subject.collecting 123
  end
end
