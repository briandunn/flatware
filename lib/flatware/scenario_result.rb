module Flatware
  class ScenarioResult
    attr_reader :status, :file_colon_line, :name
    def initialize(status, file_colon_line, name)
      @status = status
      @file_colon_line = file_colon_line
      @name = name
    end

    def passed?
      status == :passed
    end

    def failed?
      status == :failed
    end
  end
end
