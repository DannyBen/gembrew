require 'gembrew/config'
require 'gembrew/renderer'
require 'gembrew/resolver'

module Gembrew
  class Generator
    def initialize(config: Config.new, resolver: Resolver.new, renderer: Renderer.new)
      @config = config
      @resolver = resolver
      @renderer = renderer
    end

    def call
      resolution = resolver.resolve(config.gem_name, config.version)
      spec = resolution.spec
      output_path = config.output_path
      output_path.dirname.mkpath
      output_path.write renderer.render(
        formula_name: formula_name(spec.name),
        gem_name: spec.name,
        version: spec.version.to_s,
        sha256: resolution.sha256,
        description: config.description || spec.summary,
        homepage: config.homepage || inferred_homepage(spec),
        license: config.license || spec.license || spec.licenses.first,
        executable: config.executable || spec.executables.first || spec.name,
        resources: resolution.resources,
        test_body: config.test_body,
      )
      output_path
    end

  private

    attr_reader :config, :resolver, :renderer

    def formula_name(gem_name)
      gem_name.split(/[-_]/).map(&:capitalize).join
    end

    def inferred_homepage(spec)
      spec.homepage.to_s.empty? ? spec.metadata['homepage_uri'] : spec.homepage
    end
  end
end
