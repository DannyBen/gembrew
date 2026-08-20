require 'simplecov'

unless ENV['NOCOV']
  SimpleCov.start do
    enable_coverage :branch if ENV['BRANCH_COV']
    coverage_dir 'spec/coverage'
  end
end

require 'bundler'
Bundler.require :default, :development

require 'stringio'

require 'gembrew'
require 'gembrew/cli'

def fixture(name)
  File.expand_path "fixtures/#{name}", __dir__
end

def build_archive(directory, name: 'example', version: '1.2.3')
  spec = Gem::Specification.new do |gem|
    gem.name = name
    gem.version = version
    gem.summary = 'Fixture gem'
    gem.authors = ['Fixture']
    gem.files = []
  end

  filename = nil
  Dir.chdir(directory) do
    capture_output { filename = Gem::Package.build(spec, true) }
  end
  Pathname(directory)/filename
end

def capture_output
  original_stdout = $stdout
  $stdout = StringIO.new
  yield
ensure
  $stdout = original_stdout
end

ENV['TTY'] = 'off'
ENV['COLUMNS'] = '80'
ENV['LINES'] = '30'

RSpec.configure do |config|
  config.example_status_persistence_file_path = 'spec/status.txt'
  config.strip_ansi_escape = true
end
