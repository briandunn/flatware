# frozen_string_literal: true

require 'etc'

module Flatware
  module_function

  # All the pids of all the processes called flatware on this machine
  def pids
    Pids.pids { |command:, **| command =~ /flatware/ }
  end

  def pids_of_group(group_pid)
    Pids.pids { |pgid:, **| pgid == group_pid }
  end

  module Pids
    module_function

    FIELDS = %i[pid pgid ppid command].freeze

    def pids(&block)
      ps.select(&block)
        .map { |pid:, **| pid }
    end

    def ps
      args = case Etc.uname.fetch(:sysname) when 'Darwin' then ' -c' else '' end
      `ps -o#{FIELDS.map { |field| "#{field}=" }.join(',')} #{args}`
        .split("\n")
        .map do |row|
        fields = row.split(' ', 4)
        Hash[FIELDS.zip(fields.take(3).map(&:to_i) + [fields.last])]
      end
    end

    def pids_of_group(group_pid)
      ps
        .select { |pgid:, **| pgid == group_pid }
        .map { |pid:, **| pid }
    end
  end
end
