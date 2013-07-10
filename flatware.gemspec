require 'date'
$:.unshift File.expand_path "../lib", __FILE__
require 'flatware/version'

Gem::Specification.new do |s|
  s.name = "flatware"
  s.version = Flatware::VERSION
  s.authors = ["Brian Dunn"]
  s.date = Date.today.to_s
  s.summary = "A distributed cucumber runner"
  s.description = "A distributed cucumber runner"
  s.email = "brian@hashrocket.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = `git ls-files -- lib/*`.split "\n"
  s.homepage = "http://github.com/briandunn/flatware"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.executables = ["flatware"]
  s.rubygems_version = "1.8.10"
  s.add_dependency %<ffi-rzmq>, '~> 1.0.0'
  s.add_dependency %<thor>, '~> 0.13'
  s.add_dependency %<cucumber>,'>= 1.3.0'
  s.add_development_dependency %<aruba>, '~> 0.5.1'
  s.add_development_dependency %<rake>, '~> 10.0.3'
  s.add_development_dependency %<rspec>, '~> 2.13.0'
end
