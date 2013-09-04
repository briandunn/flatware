require 'flatware/serialized_exception'
module Flatware
  class ScenarioResult
    attr_reader :status, :file_colon_line, :name
    def initialize(status, file_colon_line, name, e)
      @status = status
      @file_colon_line = file_colon_line
      @name = name
      @exception = SerializedException.new(e.class, e.message, e.backtrace) if e
      @failed_outside_step = false
    end

    def passed?
      status == :passed
    end

    def failed?
      status == :failed
    end

    def failed_outside_step!(file_colon_line)
      @failed_outside_step = file_colon_line
    end

    def failed_outside_step?
      !!@failed_outside_step
    end

    def exception
      @exception.tap do |e|
        e.backtrace = e.backtrace.grep(Regexp.new(Dir.pwd)).map { |line| line[Dir.pwd.size..-1] }
        e.backtrace = e.backtrace + [@failed_outside_step] if failed_outside_step?
      end
    end
  end
end
