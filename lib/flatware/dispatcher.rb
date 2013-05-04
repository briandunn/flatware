module Flatware
  class Dispatcher
    PORT = 'ipc://dispatch'

    attr_reader :job_cue

    def self.start(jobs=Cucumber.jobs)
      new(jobs).dispatch!
    end

    def initialize(job_cue)
      @job_cue = job_cue
    end

    def dispatch!
      return if job_cue.empty?
      fireable.until_fired dispatch do |request|
        if job = job_cue.pop
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
