# frozen_string_literal: true

require 'etc'

module Flatware
  extend self
  # All the pids of all the processes called flatware on this machine
  def pids
    pids_command.map do |row|
      row =~ /(\d+).*flatware/ and $1.to_i
    end.compact
  end

  def pids_command
    case Etc.uname.fetch(:sysname)
    when 'Darwin'
      `ps -c -opid,pgid,command`
    when 'Linux'
      `ps -opid,pgid,command`
    end.split("\n")[1..-1]
  end

  def pids_of_group(group_pid)
    pids_command.map(&:split).map do |pid, pgid, _|
      pid.to_i if pgid.to_i == group_pid
    end.compact
  end
end
