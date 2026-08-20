require 'erb'
require 'fileutils'
require 'pathname'
require 'gembrew/error'

module Gembrew
  class Initializer
    CONFIG_FILENAME = 'gembrew.yml'

    attr_reader :gem_name, :project_path

    def initialize(gem_name, project_path: Pathname.pwd)
      @gem_name = gem_name
      @project_path = Pathname(project_path).expand_path
    end

    def call
      raise Error, "Directory is not empty: #{project_path} (found: #{entry_names.join(', ')})" if entries.any?

      formula_path.mkpath
      support_path.mkpath
      config_path.write render
      FileUtils.cp asset_path('compose.yaml'), compose_path

      project_path
    end

  private

    def config_path
      project_path/CONFIG_FILENAME
    end

    def compose_path
      support_path/'compose.yaml'
    end

    def formula_path
      project_path/'Formula'
    end

    def support_path
      project_path/'support'
    end

    def entries
      @entries ||= project_path.children.reject { |path| path.basename.to_s == '.git' }
    end

    def entry_names
      entries.map { |path| path.basename.to_s }.sort
    end

    def render
      template = asset_path 'gembrew.yml.erb'
      ERB.new(template.read, trim_mode: '-').result(binding)
    end

    def asset_path(filename)
      Pathname(__dir__)/'templates'/filename
    end
  end
end
