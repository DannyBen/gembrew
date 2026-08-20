lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gembrew/version'

Gem::Specification.new do |s|
  s.name        = 'gembrew'
  s.version     = Gembrew::VERSION
  s.summary     = 'Homebrew formula generator for Ruby gems'
  s.description = 'Generate conventional Homebrew formulae for published Ruby command-line gems'
  s.authors     = ['Danny Ben Shitrit']
  s.email       = 'db@dannyben.com'
  s.files       = Dir['README.md', 'LICENSE', 'lib/**/*']
  s.executables = ['gembrew']
  s.homepage    = 'https://github.com/DannyBen/gembrew'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.3'

  s.add_dependency 'bundler'
  s.add_dependency 'colsole', '~> 1.0'
  s.add_dependency 'mister_bin', '~> 0.9'

  s.metadata = {
    'bug_tracker_uri'       => 'https://github.com/DannyBen/gembrew/issues',
    'changelog_uri'         => 'https://github.com/DannyBen/gembrew/blob/master/CHANGELOG.md',
    'source_code_uri'       => 'https://github.com/DannyBen/gembrew',
    'rubygems_mfa_required' => 'true',
  }
end

