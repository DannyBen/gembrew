require 'mister_bin'
require 'gembrew/docker_check'
require 'gembrew/generator'

module Gembrew
  module Commands
    class Check < MisterBin::Command
      help 'Build and test formulae in clean Homebrew environments'

      usage 'gembrew check [GEM]'
      usage 'gembrew check (-h|--help)'

      param 'GEM', 'Optional gem configuration name'

      def run
        configs.each do |config|
          say "bb`==> gembrew: building #{config.name}`"
          output_path = Generator.new(config: config).call
          say "Generated m`#{output_path}`"
          DockerCheck.new.call output_path.basename('.rb').to_s
        end
        say 'g`All checks passed`'
      end

    private

      def configs
        args['GEM'] ? [Config.find(args['GEM'])] : Config.all
      end
    end
  end
end
