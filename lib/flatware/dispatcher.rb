module Flatware
  class Dispatcher
    def self.dispatch!
      ZMQ::Context.new(1).tap do |context|
        context.socket(ZMQ::REP).tap do |jobs|
          context.socket(ZMQ::PULL).tap do |sink|
            sink.bind 'tcp://*:5556'
            jobs.bind 'tcp://*:5555'
            while message = ZMQ.select([sink, jobs]).flatten.first.recv
              # exit loop on signals
              if message == 'READY'
                jobs.send YAML.dump Flatware::Job.new (rand(1..10))
              else
                puts message
              end
            end
            sink.close
            jobs.close
          end
        end
        context.close
      end
    end
  end
end
