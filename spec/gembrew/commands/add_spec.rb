require 'spec_helper'
require 'tmpdir'

describe Gembrew::Commands::Add do
  subject { described_class }

  it 'adds a gem configuration to the current tap' do
    Dir.mktmpdir do |directory|
      (Pathname(directory)/'Formula').mkpath

      Dir.chdir(directory) do
        expect { subject.execute %w[add example] }
          .to output("Added #{directory}/gembrew/example\n").to_stdout
      end

      expect(File).to exist("#{directory}/gembrew/example/formula.yml")
    end
  end
end
