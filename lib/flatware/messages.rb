module Flatware
  Job = Struct.new :hardness do
    def sleepiness
      hardness * 0.1
    end

    def call
      sleep sleepiness
      sleepiness
    end

    def pid
      ::Process.pid
    end
  end
end
