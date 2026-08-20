require 'erb'
require 'pathname'
require 'gembrew/config'
require 'gembrew/error'

module Gembrew
  class Adder
    attr_reader :gem_name, :project_path

    def initialize(gem_name, project_path: Pathname.pwd)
      @gem_name = gem_name
      @project_path = Pathname(project_path).expand_path
    end

    def call
      Config.validate_name! gem_name
      unless formula_path.directory?
        raise Error, "Directory is not a Homebrew tap: #{project_path} (Formula/ does not exist)"
      end

      config_directory.mkpath
      raise Error, "Gem configuration already exists: #{config_path}" if config_path.exist?

      config_path.write render
      config_path
    end

  private

    def formula_path = project_path/'Formula'
    def config_directory = project_path/'gembrew'
    def config_path = config_directory/"#{gem_name}.yml"

    def render
      template = Pathname(__dir__)/'templates/gembrew.yml.erb'
      ERB.new(template.read, trim_mode: '-').result(binding)
    end
  end
end
