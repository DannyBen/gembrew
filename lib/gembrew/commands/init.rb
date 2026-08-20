require 'mister_bin'
require 'gembrew/initializer'

module Gembrew
  module Commands
    class Init < MisterBin::Command
      help 'Initialize a Homebrew tap repository'

      usage 'gembrew init [GEM]'
      usage 'gembrew init (-h|--help)'

      param 'GEM', 'Optional published Ruby gem name'

      def run
        Initializer.new(args['GEM']).call
        message = "Initialized m`#{Dir.pwd}`"
        message += " for bb`#{args['GEM']}`" if args['GEM']
        say message
      end
    end
  end
end
