module Flatware
  class Dispatcher
    def self.spawn(jobs, endpoint)
      fork do
        $0 = 'flatware dispatcher'
        trap('INT') { exit 1 }
        new(jobs, endpoint).dispatch!
      end
    end

    def initialize(jobs, endpoint)
      @jobs     = jobs
      @fireable = Fireable.new
      @dispatch = Flatware.socket ZMQ::REP, bind: endpoint
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
