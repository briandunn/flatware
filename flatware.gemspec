# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "flatware"
  s.version = "0.0.0"
  s.authors = ["Brian Dunn"]
  s.date = "2012-02-24"
  s.summary = "A distributing drop in replacement for Spork"
  s.description = "A distributing drop in replacement for Spork"
  s.email = "brian@theophil.us"
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
  s.add_dependency %<zmq>
  s.add_dependency %<thor>,'~> 0.15.0'
  s.add_development_dependency %<aruba>
  s.add_development_dependency %<rake>
  s.add_development_dependency %<rspec>
end

