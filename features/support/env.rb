require 'pathname'

$:.unshift Pathname.new(__FILE__).dirname.join('../../lib').to_s

ENV['PATH'] = [Pathname.new('.').expand_path.join('bin').to_s, ENV['PATH']].join(':')

Before { @dirs = ['tmp', "aruba#{ENV['TEST_ENV_NUMBER']}"] }

require 'aruba/cucumber'
require 'rspec/expectations'
require 'flatware/processor_info'
World(Module.new do
  def max_workers
    return 3 if ENV['TRAVIS'] == 'true'
    Flatware::ProcessorInfo.count
  end
end)
