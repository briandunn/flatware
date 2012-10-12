module Flatware
  class ProcessorInfo
    def count
      case operating_system
      when 'Darwin'
        `hostinfo`.match(/^(?<processors>\d+) processors are logically available\.$/)[:processors].to_i
      when 'Linux'
        `grep --count '^processor' /proc/cpuinfo`.to_i
      end
    end

    def operating_system
      `uname`.chomp
    end

    def self.count
      new.count
    end
  end
end
