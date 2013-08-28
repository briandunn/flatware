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

  def travis?
    ENV['TRAVIS'] == 'true'
  end
end)

Before do
  if travis?
    @announce_stdout = true
    @announce_stderr = true
    @announce_cmd = true
    @announce_dir = true
    @announce_env = true
  end
end

After do
  if travis?
    system 'flatware clear'
    Process.waitall
  end
end

After '~@non-zero' do
  assert_exit_status 0
end

After '@non-zero' do
  assert_exit_status 1
end
