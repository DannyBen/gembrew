require 'mister_bin'
require 'gembrew/generator'

module Gembrew
  module Commands
    class Build < MisterBin::Command
      help 'Generate a Homebrew formula from gembrew.yml'

      usage 'gembrew build'
      usage 'gembrew build (-h|--help)'

      def run
        output_path = Generator.new.call
        say "Generated m`#{output_path}`"
      end
    end
  end
end
