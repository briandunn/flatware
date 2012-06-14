module Flatware
  class Sink
    class << self
      def push(message)
        client.push message
      end

      def disconnect
        client.disconnect
      end

      def start_server
        fork do
          Server.start
        end
      end

      def client
        @client ||= Client.new
      end
    end

    module Server
      extend self

      def start
        while message = socket.recv
          print message
        end
      end

      def socket
        @socket ||= ZMQ::Context.new(1).socket(ZMQ::PULL).tap do |socket|
          socket.bind 'ipc://sink'
        end
      end
    end

    class Client
      def push(message)
        socket.send message
      end

      def disconnect
        socket.send ''
        socket.close
      end

      private

      def socket
        @socket ||= context.socket(ZMQ::PUSH).tap do |socket|
          socket.connect 'ipc://sink'
        end
      end

      def context
        Worker.context
      end
    end
  end
end
