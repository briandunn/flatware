module Flatware
  extend self
  # All the pids of all the processes called flatware on this machine
  def pids
    pids_command.split("\n").map do |row|
      row =~ /(\d+).*flatware/ and $1.to_i
    end.compact
  end

  def pids_command
    case ProcessorInfo.operating_system
    when 'Darwin'
      `ps -c -opid,command`
    when 'Linux'
      `ps -opid,command`
    end
  end
end
