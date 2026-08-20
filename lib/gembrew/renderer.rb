require 'erb'
require 'pathname'

module Gembrew
  class Renderer
    def render(locals)
      context = Object.new
      locals.each { |name, value| context.define_singleton_method(name) { value } }
      ERB.new(template_path.read, trim_mode: '-').result(context.instance_eval { binding })
    end

  private

    def template_path
      Pathname(__dir__)/'templates/formula.rb.erb'
    end
  end
end
