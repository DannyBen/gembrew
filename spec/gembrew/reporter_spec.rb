require 'spec_helper'

describe Gembrew::Reporter do
  subject(:reporter) { described_class.new }

  it 'aligns counters to totals with three digits' do
    expect(reporter).to receive(:say)
      .with('  1/123  g`RubyGems cache`  nb`first` 1.0.0')
    expect(reporter).to receive(:say)
      .with('100/123  g`Gembrew cache `  nb`second` 2.0.0')

    reporter.archive :rubygems_cache, 'first', '1.0.0', index: 1, total: 123
    reporter.archive :gembrew_cache, 'second', '2.0.0', index: 100, total: 123
  end

  it 'uses yellow for downloads and bold for gem names' do
    expect(reporter).to receive(:say)
      .with(' 9/26  y`Downloading   `  nb`example` 1.2.3')

    reporter.archive :downloading, 'example', '1.2.3', index: 9, total: 26
  end

  it 'omits the counter for the root archive' do
    expect(reporter).to receive(:say).with('y`Downloading   `  nb`example`')

    reporter.archive :downloading, 'example', nil
  end

  it 'reports resolution phases' do
    expect(reporter).to receive(:say)
      .with('Resolving dependencies for nb`example` 1.2.3...')
    expect(reporter).to receive(:say)
      .with('Collecting nb`123` resources...')

    reporter.resolving 'example', '1.2.3'
    reporter.collecting 123
  end
end
