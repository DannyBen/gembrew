require 'mister_bin'
require 'gembrew/docker_check'
require 'gembrew/generator'

module Gembrew
  module Commands
    class Check < MisterBin::Command
      help 'Build and test the formula in a clean Homebrew environment'

      usage 'gembrew check'
      usage 'gembrew check (-h|--help)'

      def run
        output_path = Generator.new.call
        say "Generated m`#{output_path}`"
        DockerCheck.new.call
        say 'g`All checks passed`'
      end
    end
  end
end
