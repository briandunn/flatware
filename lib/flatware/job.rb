module Flatware
  Job = Struct.new :id, :args do
    attr_accessor :worker
    attr_writer :failed

    def failed?
      @failed == true
    end
  end
end
