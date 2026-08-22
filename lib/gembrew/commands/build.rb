require 'mister_bin'
require 'gembrew/generator'

module Gembrew
  module Commands
    class Build < MisterBin::Command
      help 'Generate Homebrew formulae from gembrew/*/formula.yml'

      usage 'gembrew build [GEM]'
      usage 'gembrew build (-h|--help)'

      param 'GEM', 'Optional gem configuration name'

      def run
        configs.each do |config|
          say "bb`==> gembrew: building #{config.name}`"
          output_path = Generator.new(config: config).call
          say "Generated m`#{output_path}`"
        end
      end

    private

      def configs
        args['GEM'] ? [Config.find(args['GEM'])] : Config.all
      end
    end
  end
end
