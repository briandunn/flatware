module Flatware
  extend self
  # All the pids of all the processes called flatware on this machine
  def pids
    `ps -c -opid,command`.split("\n").map do |row|
      row =~ /(\d+).*flatware/ and $1.to_i
    end.compact
  end
end
