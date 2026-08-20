require 'mister_bin'
require 'gembrew/commands/build'
require 'gembrew/commands/init'
require 'gembrew/version'

module Gembrew
  class CLI
    def self.runner
      runner = MisterBin::Runner.new version: Gembrew::VERSION,
        header: 'Gembrew - Homebrew Formula Generator for Ruby Gems',
        footer: 'Run m`gembrew COMMAND --help` for more information'

      runner.route 'init',  to: Commands::Init
      runner.route 'build', to: Commands::Build

      runner
    end
  end
end

