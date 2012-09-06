# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "flatware"
  s.version = "0.0.1"
  s.authors = ["Brian Dunn"]
  s.date = "2012-02-24"
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
  s.add_dependency %<zmq>
  s.add_dependency %<thor>, '> 0.13', '< 0.16'
  s.add_dependency %<cucumber>,'~> 1.2.0'
  s.add_development_dependency %<aruba>
  s.add_development_dependency %<rake>
  s.add_development_dependency %<rspec>
end

