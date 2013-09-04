module Flatware
  class SpawnProcess < Aruba::SpawnProcess
    attr_reader :pid
    def run!
      super { |process| @pid = @process.pid }
    end
  end
end
