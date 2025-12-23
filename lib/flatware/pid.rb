# frozen_string_literal: true

require 'etc'

module Flatware
  module_function

  # All the pids of all the processes called flatware on this machine
  def pids
    Pid.pids { |pid| pid.command =~ /flatware/ }
  end

  def pids_of_group(group_pid)
    Pid.pids { |pid| pid.pgid == group_pid }
  end

  Pid = Struct.new(:pid, :pgid, :ppid, :command) do
    def self.pids(&block)
      ps.select(&block).map(&:pid)
    end

    def self.ps
      args = ['-o', members.join(',')]
      args += { 'Darwin' => %w[-c] }.fetch(Etc.uname.fetch(:sysname), [])

      IO
        .popen(['ps', *args])
        .readlines
        .map do |row|
          fields = row.strip.split(/\s+/, 4)
          new(*fields.take(3).map(&:to_i), fields.last)
        end
    end

    def pids_of_group(group_pid)
      ps
        .select { |pid| pid.pgid == group_pid }
        .map(&:pid)
    end
  end
end
