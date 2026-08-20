require 'mister_bin'
require 'gembrew/docker_shell'

module Gembrew
  module Commands
    class Shell < MisterBin::Command
      help 'Open a Homebrew shell for this tap repository'

      usage 'gembrew shell [--pristine]'
      usage 'gembrew shell (-h|--help)'

      option '-p --pristine', 'Open without mounting the local tap'

      def run
        DockerShell.new.call pristine: args['--pristine']
      end
    end
  end
end
