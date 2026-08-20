require 'mister_bin'
require 'gembrew/adder'

module Gembrew
  module Commands
    class Add < MisterBin::Command
      help 'Add a Ruby gem to this tap repository'

      usage 'gembrew add GEM'
      usage 'gembrew add (-h|--help)'

      param 'GEM', 'Published Ruby gem name'

      def run
        path = Adder.new(args['GEM']).call
        say "Added m`#{path}`"
      end
    end
  end
end
