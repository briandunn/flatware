module Flatware
  class Worker
    def self.listen!
      ZMQ::Context.new(1).tap do |context|
        context.socket(ZMQ::REQ).tap do |socket|
          sink = context.socket(ZMQ::PUSH)
          socket.connect 'tcp://localhost:5555'
          sink.connect 'tcp://localhost:5556'
          socket.send 'READY'
          begin
            while message = socket.recv
              obj = YAML.load(message)
              print "#{obj.call}  "
              sink.send obj.pid.to_s
              socket.send 'READY'
            end
          ensure
            puts
            socket.close
            sink.close
          end
        end
        context.close
      end
    end
  end
end
