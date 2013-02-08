module Flatware
  class Dispatcher
    PORT = 'ipc://dispatch'

    def self.start(jobs=Cucumber.jobs)
      new(jobs).dispatch!
    end

    def initialize(jobs)
      @jobs = jobs
    end

    def dispatch!
      return if jobs.empty?
      fireable.until_fired dispatch do |request|
        if job = jobs.pop
          dispatch.send job
        else
          dispatch.send 'seppuku'
        end
      end
    end

    private

    attr_reader :jobs

    def fireable
      @fireable ||= Fireable.new
    end

    def dispatch
      @dispatch ||= Flatware.socket ZMQ::REP, bind: PORT
    end
  end
end
