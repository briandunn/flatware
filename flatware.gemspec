# frozen_string_literal: true

require 'date'
$LOAD_PATH.unshift File.expand_path 'lib', __dir__
require 'flatware/version'
runners = %w[rspec cucumber]
summary = format(
  'A distributed %<runners>s runner',
  runners: runners.join(' and ')
)

Gem::Specification.new do |s|
  s.name = 'flatware'
  s.version = Flatware::VERSION
  s.authors = ['Brian Dunn']
  s.date = Date.today.to_s
  s.summary = summary
  s.description = summary
  s.email = 'brian@hashrocket.com'
  s.extra_rdoc_files = [
    'LICENSE.txt',
    'README.md'
  ]
  s.files = `git ls-files -- lib`.each_line
                                 .map(&:chomp)
                                 .grep(/^((?!#{Regexp.union(runners)}).)*$/)
  s.homepage = 'http://github.com/briandunn/flatware'

  s.licenses = ['MIT']
  s.required_ruby_version = '>= 2.1'
  s.require_paths = ['lib']
  s.executables = ['flatware']
  s.add_dependency %(ffi-rzmq), '~> 2.0'
  s.add_dependency %(thor), '< 2.0'
  s.add_development_dependency %(aruba), '~> 1.0'
  s.add_development_dependency %(rake), '~> 10.1.0'
end
