require 'spec_helper'
require 'tmpdir'

describe Gembrew::Commands::Init do
  subject { described_class }

  it 'initializes the current directory for the requested gem' do
    Dir.mktmpdir do |directory|
      Dir.chdir(directory) do
        expect { subject.execute %w[init example] }
          .to output("Initialized #{directory} for example\n").to_stdout
      end

      expect(File).to exist("#{directory}/gembrew.yml")
    end
  end
end
