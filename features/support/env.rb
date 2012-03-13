require 'pathname'

$:.unshift Pathname.new(__FILE__).dirname.join('../../lib').to_s

ENV['PATH'] = [Pathname.new('.').expand_path.join('bin').to_s, ENV['PATH']].join(':')
require 'aruba/cucumber'
require 'rspec/expectations'
