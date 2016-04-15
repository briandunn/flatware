require 'pathname'

$:.unshift Pathname.new(__FILE__).dirname.join('../../lib').to_s

ENV['PATH'] = [Pathname.new('.').expand_path.join('bin').to_s, ENV['PATH']].join(':')

require 'flatware/pids'

Before { @dirs = ['tmp', "aruba#{ENV['TEST_ENV_NUMBER']}"] }

require 'aruba/cucumber'
require 'rspec/expectations'
require 'flatware/processor_info'

require File.join(Pathname.new(__FILE__).dirname, 'flatware/spawn_process')
# Aruba.process = Flatware::SpawnProcess

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

After do |scenario|
  if all_commands.count > 0
    zombie_pids = Flatware.pids_of_group(all_commands[0].pid)

    (Flatware.pids - [$$]).each do |pid|
      Process.kill 6, pid
    end
    Process.waitall
    expect(zombie_pids.size).to(eq(0), "Zombie pids: #{zombie_pids.size}, should be 0")
  end
end

After do
  if travis?
    system 'flatware clear'
    Process.waitall
  end
end

After '~@non-zero' do |scenario|
  if flatware_process and scenario.status == :passed
    expect(flatware_process.exit_status).to eq 0
  end
end

After '@non-zero' do |scenario|
  if flatware_process and scenario.status == :passed
    expect(flatware_process.exit_status).to eq 1
  end
end
