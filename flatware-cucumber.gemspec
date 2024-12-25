# frozen_string_literal: true

require 'date'
$LOAD_PATH.unshift File.expand_path 'lib', __dir__
require 'flatware/version'

Gem::Specification.new do |s|
  s.name = 'flatware-cucumber'
  s.version = Flatware::VERSION
  s.authors = ['Brian Dunn']
  s.summary = 'A distributed cucumber runner'
  s.description = 'A distributed cucumber runner'
  s.email = 'brian@hashrocket.com'
  s.extra_rdoc_files = [
    'LICENSE.txt',
    'README.md'
  ]
  s.files = (`git ls-files -- lib/flatware/cucumber`.split("\n") +
             %w[lib/flatware-cucumber.rb lib/flatware/cucumber.rb]
            )
  s.homepage = 'http://github.com/briandunn/flatware'
  s.licenses = ['MIT']
  s.required_ruby_version = ['>= 2.6', '< 3.5']
  s.require_paths = ['lib']
  s.add_dependency %(cucumber), '~> 3.0'
  s.add_dependency %(flatware), Flatware::VERSION
  # s.metadata['rubygems_mfa_required'] = 'true'
end
