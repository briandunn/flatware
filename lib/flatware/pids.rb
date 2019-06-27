# frozen_string_literal: true

require 'etc'

module Flatware
  module_function

  # All the pids of all the processes called flatware on this machine
  def pids
    ps.select { |command:, **| command =~ /flatware/ }
      .map { |pid:, **| pid }
  end

  def ps
    args = case Etc.uname.fetch(:sysname)
           when 'Darwin'
             ' -c '
           else
             ''
           end
    `ps -opid=,pgid=,command= #{args}`.split("\n").map do |row|
      pid, pgid, command = row.split(' ', 3)
      Hash[%i[pid pgid command].zip([pid, pgid].map(&:to_i) + [command])]
    end
  end

  def pids_of_group(group_pid)
    ps
      .select { |pgid:, **| pgid == group_pid }
      .map { |pid:, **| pid }
  end
end
