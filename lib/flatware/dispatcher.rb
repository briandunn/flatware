module Flatware
  class Dispatcher
    DISPATCH_PORT = 'ipc://dispatch'

    def self.start(jobs=Cucumber.jobs)
      new(jobs).dispatch!
    end

    def initialize(jobs)
      @jobs = jobs
    end

    def dispatch!
      fireable.until_fired dispatch do |request|
        if job = jobs.pop
          dispatch.send Marshal.dump job
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
      @dispatch ||= Flatware.socket(ZMQ::REP).tap do |socket|
        socket.bind DISPATCH_PORT
      end
    end
  end
end
