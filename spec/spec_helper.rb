require 'simplecov'

unless ENV['NOCOV']
  SimpleCov.start do
    enable_coverage :branch if ENV['BRANCH_COV']
    coverage_dir 'spec/coverage'
  end
end

require 'bundler'
Bundler.require :default, :development

require 'gembrew'
require 'gembrew/cli'

ENV['TTY'] = 'off'
ENV['COLUMNS'] = '80'
ENV['LINES'] = '30'

RSpec.configure do |config|
  config.example_status_persistence_file_path = 'spec/status.txt'
  config.strip_ansi_escape = true
end
