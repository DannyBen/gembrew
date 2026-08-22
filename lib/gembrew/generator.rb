require 'gembrew/config'
require 'gembrew/renderer'
require 'gembrew/resolver'

module Gembrew
  class Generator
    def initialize(config:, resolver: Resolver.new, renderer: Renderer.new)
      @config = config
      @resolver = resolver
      @renderer = renderer
    end

    def call
      resolution = resolver.resolve(config.gem_name, config.version, source: config.source)
      output_path = config.output_path
      output_path.dirname.mkpath
      output_path.write renderer.render(formula_data(resolution))
      output_path
    end

  private

    attr_reader :config, :resolver, :renderer

    def formula_data(resolution)
      spec = resolution.spec
      {
        formula_name: formula_name(spec.name),
        gem_name:     spec.name,
        version:      spec.version.to_s,
        sha256:       resolution.sha256,
        resources:    resolution.resources,
      }.merge metadata(spec)
    end

    def metadata(spec)
      {
        description:        config.description || spec.summary,
        homepage:           config.homepage || inferred_homepage(spec),
        license:            config.license || spec.license || spec.licenses.first,
        executable:         executable(spec),
        source_type:        config.source_type,
        source_repo:        config.source_repo,
        source_tag:         config.source_tag,
        source_gemspec:     config.source_gemspec,
        dependencies:       formula_dependencies,
        install_extra_body: config.install_extra_body,
        test_body:          config.test_body || %[system bin/#{executable(spec).inspect}, "--version"\n],
      }
    end

    def executable(spec)
      config.executable || spec.executables.first || spec.name
    end

    def formula_dependencies
      ([Config::Dependency.new(name: 'ruby', tags: [])] + config.dependencies)
        .uniq(&:name)
        .sort_by(&:name)
    end

    def formula_name(gem_name)
      gem_name.split(/[-_]/).map(&:capitalize).join
    end

    def inferred_homepage(spec)
      spec.homepage.to_s.empty? ? spec.metadata['homepage_uri'] : spec.homepage
    end
  end
end
