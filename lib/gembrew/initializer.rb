require 'erb'
require 'fileutils'
require 'pathname'
require 'gembrew/adder'
require 'gembrew/error'

module Gembrew
  class Initializer
    attr_reader :gem_name, :project_path

    def initialize(gem_name = nil, project_path: Pathname.pwd)
      @gem_name = gem_name
      @project_path = Pathname(project_path).expand_path
    end

    def call
      Config.validate_name! gem_name if gem_name
      validate_project

      formula_path.mkpath
      config_directory.mkpath
      readme_path.write render_readme unless readme_path.exist?
      Adder.new(gem_name, project_path: project_path).call if gem_name

      project_path
    end

  private

    def formula_path
      project_path/'Formula'
    end

    def config_directory
      project_path/'gembrew'
    end

    def readme_path
      project_path/'README.md'
    end

    def entries
      @entries ||= project_path.children.reject { |path| path.basename.to_s == '.git' }
    end

    def validate_project
      return if entries.empty? || formula_path.directory?

      raise Error, "Directory is not a Homebrew tap: #{project_path} (Formula/ does not exist)"
    end

    def render_readme
      template = Pathname(__dir__)/'templates/README.md.erb'
      ERB.new(template.read, trim_mode: '-').result(binding)
    end
  end
end
