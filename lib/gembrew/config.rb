require 'pathname'
require 'yaml'
require 'gembrew/error'

module Gembrew
  class Config
    DIRECTORY = 'gembrew'
    ALLOWED_KEYS = %w[
      gem version source output desc homepage license executable dependencies test test_from_file
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
    def source = data.fetch('source')
    def source_type = source.fetch('type')
    def source_repo = source['repo']
    def source_tag = source['tag'] || "v#{version}"
    def source_gemspec = source['gemspec'] || "#{gem_name}.gemspec"
    def output_path = (project_path/(data['output'] || "Formula/#{name}.rb")).expand_path
    def description = data['desc']
    def homepage = data['homepage']
    def license = data['license']
    def executable = data['executable']
    def dependencies = data.fetch('dependencies', [])

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
      require_value 'version'
      require_value 'source'
      validate_source
      validate_dependencies

      return unless data.has_key?('test') == data.has_key?('test_from_file')

      raise Error, 'Provide exactly one of test or test_from_file'
    end

    def require_value(key)
      value = data[key]
      raise Error, "#{key} is required" if value.nil? || value.to_s.empty?
    end

    def validate_source
      raise Error, 'source must be a mapping' unless source.is_a?(Hash)

      unknown_keys = source.keys - %w[type repo tag gemspec]
      raise Error, "Unknown source keys: #{unknown_keys.join(', ')}" if unknown_keys.any?

      type = source['type']&.to_s
      raise Error, 'source.type must be github or rubygems' unless %w[github rubygems].include? type

      if type == 'rubygems'
        extra_keys = source.keys - ['type']
        raise Error, "source.#{extra_keys.first} is only valid for GitHub sources" if extra_keys.any?
        return
      end

      repo = source['repo']&.to_s
      raise Error, 'source.repo is required for GitHub sources' if repo.nil? || repo.empty?
      raise Error, 'source.repo must be in owner/repository form' unless repo.match?(%r{\A[^/\s]+/[^/\s]+\z})

      validate_relative_source_path 'gemspec' if source.has_key?('gemspec')
      raise Error, 'source.tag must not be empty' if source.has_key?('tag') && source['tag'].to_s.empty?
    end

    def validate_relative_source_path(key)
      value = source[key].to_s
      path = Pathname(value)
      valid = !value.empty? && !path.absolute? && path.each_filename.none? { |part| part == '..' }
      raise Error, "source.#{key} must be a relative path within the archive" unless valid
    end

    def validate_dependencies
      return unless data.has_key?('dependencies')

      dependencies = data['dependencies']
      valid = dependencies.is_a?(Array) &&
        dependencies.all? { |dependency| dependency.is_a?(String) && !dependency.empty? }
      raise Error, 'dependencies must be a sequence of names' unless valid
    end
  end
end
