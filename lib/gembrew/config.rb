require 'pathname'
require 'yaml'
require 'gembrew/error'

module Gembrew
  class Config
    DIRECTORY = 'gembrew'
    ALLOWED_KEYS = %w[
      gem version repository output desc homepage license executable test test_from_file
    ].freeze

    attr_reader :path, :project_path

    def self.all(project_path = Pathname.pwd)
      project_path = Pathname(project_path).expand_path
      paths = (project_path/DIRECTORY).glob('*.yml').sort
      raise Error, "No gem configurations found in #{project_path/DIRECTORY}" if paths.empty?

      paths.map { |path| new path, project_path: project_path }
    end

    def self.find(name, project_path = Pathname.pwd)
      validate_name! name
      project_path = Pathname(project_path).expand_path
      new project_path/DIRECTORY/"#{name}.yml", project_path: project_path
    end

    def self.validate_name!(name)
      return name if name&.match?(/\A[a-zA-Z0-9._-]+\z/)

      raise Error, "Invalid gem name: #{name.inspect}"
    end

    def initialize(path, project_path: nil)
      @path = Pathname(path).expand_path
      @project_path = project_path ? Pathname(project_path).expand_path : @path.dirname.parent
      @data = load_data
      validate
    end

    def name = path.basename('.yml').to_s
    def gem_name = data.fetch('gem').to_s
    def version = data['version']&.to_s
    def repository
      value = data['repository']&.to_s
      return if value.nil? || value.empty?
      return value if value.start_with?('https://')

      "https://github.com/#{value}"
    end
    def output_path = (project_path/(data['output'] || "Formula/#{name}.rb")).expand_path
    def description = data['desc']
    def homepage = data['homepage']
    def license = data['license']
    def executable = data['executable']

    def test_body
      @test_body ||= if data.has_key?('test')
        data.fetch('test').to_s
      else
        test_path = project_path/data.fetch('test_from_file')
        raise Error, "Test file does not exist: #{test_path}" unless test_path.file?

        test_path.read
      end
    end

  private

    attr_reader :data

    def load_data
      raise Error, "Configuration does not exist: #{path}" unless path.file?

      YAML.safe_load_file(path, aliases: false)
    rescue Psych::Exception => e
      raise Error, "Invalid configuration: #{e.message}"
    end

    def validate
      raise Error, 'Configuration must be a YAML mapping' unless data.is_a?(Hash)

      unknown_keys = data.keys - ALLOWED_KEYS
      raise Error, "Unknown configuration keys: #{unknown_keys.join(', ')}" if unknown_keys.any?

      require_value 'gem'
      validate_repository

      return unless data.has_key?('test') == data.has_key?('test_from_file')

      raise Error, 'Provide exactly one of test or test_from_file'
    end

    def require_value(key)
      value = data[key]
      raise Error, "#{key} is required" if value.nil? || value.to_s.empty?
    end

    def validate_repository
      return unless data.has_key?('repository')

      value = data['repository'].to_s
      valid = value.match?(%r{\Ahttps://\S+\z}) || value.match?(%r{\A[^/\s]+/[^/\s]+\z})
      raise Error, 'repository must be an HTTPS URL or owner/repository' unless valid
    end
  end
end
