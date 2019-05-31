# frozen_string_literal: true

require 'pathname'

$LOAD_PATH.unshift Pathname.new(__FILE__).dirname.join('../../lib').to_s

ENV['PATH'] = [Pathname('.').expand_path.join('bin'), ENV['PATH']].join(':')

require 'flatware/pids'

Before { @dirs = ['tmp', "aruba#{ENV['TEST_ENV_NUMBER']}"] }

require 'aruba/cucumber'
require 'aruba/api'
require 'rspec/expectations'
require 'flatware/processor_info'

World(Module.new do
  def max_workers
    return 3 if travis?

    Flatware::ProcessorInfo.count
  end

  def travis?
    ENV['TRAVIS'] == 'true'
  end
end)

Before do
  if travis?
    %i[
      command
      directory
      environment
      stderr
      stdout
    ].each(&aruba.announcer.method(:activate))
  end
end

After do |_scenario|
  if all_commands.any?
    zombie_pids = Flatware.pids_of_group(all_commands[0].pid)

    (Flatware.pids - [$PROCESS_ID]).each do |pid|
      Process.kill 6, pid
    end
    Process.waitall
    expect(zombie_pids.size).to(
      eq(0),
      "Zombie pids: #{zombie_pids.size}, should be 0"
    )
  end
end

After 'not @non-zero' do |scenario|
  if flatware_process && (scenario.status == :passed)
    expect(flatware_process.exit_status).to eq 0
  end
end

After '@non-zero' do |scenario|
  if flatware_process && (scenario.status == :passed)
    expect(flatware_process.exit_status).to eq 1
  end
end
