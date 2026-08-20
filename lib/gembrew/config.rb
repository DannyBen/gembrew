require 'pathname'
require 'yaml'
require 'gembrew/error'

module Gembrew
  class Config
    FILENAME = 'gembrew.yml'
    ALLOWED_KEYS = %w[
      gem version output desc homepage license executable test test_from_file
    ].freeze

    attr_reader :path

    def initialize(project_path = Pathname.pwd)
      @path = Pathname(project_path).expand_path/FILENAME
      @data = load_data
      validate
    end

    def gem_name = data.fetch('gem').to_s
    def version = data['version']&.to_s
    def output_path = (path.dirname/data.fetch('output')).expand_path
    def description = data['desc']
    def homepage = data['homepage']
    def license = data['license']
    def executable = data['executable']

    def test_body
      @test_body ||= if data.key?('test')
        data.fetch('test').to_s
      else
        test_path = path.dirname/data.fetch('test_from_file')
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
      require_value 'output'

      return unless data.key?('test') == data.key?('test_from_file')

      raise Error, 'Provide exactly one of test or test_from_file'
    end

    def require_value(key)
      value = data[key]
      raise Error, "#{key} is required" if value.nil? || value.to_s.empty?
    end
  end
end
