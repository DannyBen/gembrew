require 'spec_helper'

describe Gembrew do
  it 'has a version' do
    expect(Gembrew::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
