module Flatware
  class Dispatcher
    PORT = 'ipc://dispatch'

    def self.start(jobs)
      trap 'INT' do
        Flatware.close
        exit 1
      end
      new(jobs).dispatch!
    end

    def initialize(jobs)
      @jobs     = jobs
      @fireable = Fireable.new
      @dispatch = Flatware.socket ZMQ::REP, bind: PORT
    end

    def dispatch!
      fireable.until_fired dispatch do |request|
        if job = jobs.shift
          dispatch.send job
        else
          dispatch.send 'seppuku'
        end
      end
    end

    private

    attr_reader :jobs, :fireable, :dispatch
  end
end
