# frozen_string_literal: true

require 'date'
$LOAD_PATH.unshift File.expand_path 'lib', __dir__
require 'flatware/version'

Gem::Specification.new do |s|
  s.name = 'flatware-rspec'
  s.version = Flatware::VERSION
  s.authors = ['Brian Dunn']
  s.summary = 'A distributed rspec runner'
  s.description = 'A distributed rspec runner'
  s.email = 'brian@hashrocket.com'
  s.extra_rdoc_files = [
    'LICENSE.txt',
    'README.md'
  ]
  s.files = (
            `git ls-files -- lib/flatware/rspec`.split("\n") +
            %w[lib/flatware-rspec.rb lib/flatware/rspec.rb]
          )
  s.homepage = 'http://github.com/briandunn/flatware'
  s.licenses = ['MIT']
  s.required_ruby_version = ['>= 2.6', '< 3.5']
  s.require_paths = ['lib']
  s.add_dependency %(flatware), Flatware::VERSION
  s.add_dependency %(rspec), '>= 3.6'
  # s.metadata['rubygems_mfa_required'] = 'true'
end
