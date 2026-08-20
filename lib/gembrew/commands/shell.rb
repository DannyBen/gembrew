require 'mister_bin'
require 'gembrew/docker_shell'

module Gembrew
  module Commands
    class Shell < MisterBin::Command
      help 'Open a Homebrew shell for this tap repository'

      usage 'gembrew shell'
      usage 'gembrew shell (-h|--help)'

      def run
        DockerShell.new.call
      end
    end
  end
end
