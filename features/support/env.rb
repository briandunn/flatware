# frozen_string_literal: true

require 'pathname'

$LOAD_PATH.unshift Pathname.new(__FILE__).dirname.join('../../lib').to_s

ENV['PATH'] = [Pathname('.').expand_path.join('bin'), ENV['PATH']].join(':')

require 'flatware/pids'
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
    ENV.key? 'TRAVIS'
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
  all_commands.reject(&:stopped?).each do |command|
    zombie_pids = Flatware.pids_of_group(command.pid)

    zombie_pids.each do |pid|
      $stderr.puts "kill #{`ps -oCOMMAND ${pid}`}"
      Process.kill 6, pid
      Process.wait pid, Process::WUNTRACED
    rescue Errno::ECHILD
      next
    end

    expect(zombie_pids).not_to(
      be_any,
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
