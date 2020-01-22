module Flatware
  Job = Struct.new :id, :args do
    attr_accessor :worker
    attr_writer :failed

    def failed?
      @failed == true
    end

    def failed!
      @failed = true
    end

    def sentinel?
      id == 'seppuku'
    end

    def self.sentinel
      new 'seppuku'
    end
  end
end
