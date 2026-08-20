require 'mister_bin'
require 'gembrew/initializer'

module Gembrew
  module Commands
    class Init < MisterBin::Command
      help 'Initialize a Homebrew tap repository for a Ruby gem'

      usage 'gembrew init GEM'
      usage 'gembrew init (-h|--help)'

      param 'GEM', 'Published Ruby gem name'

      def run
        Initializer.new(args['GEM']).call
        say "Initialized m`#{Dir.pwd}` for bb`#{args['GEM']}`"
      end
    end
  end
end
