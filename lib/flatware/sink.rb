require 'flatware'
module Flatware
  class Sink
    class << self
      def push(message)
        client.push message
      end

      def start_server
        Server.start
      end

      def client
        @client ||= Client.new
      end
    end

    module Server
      extend self

      def start
        fireable.until_fired socket do |message|
          print message
        end
      end

      private

      def fireable
        Fireable.new
      end

      def socket
        @socket ||= Flatware.socket(ZMQ::PULL).tap do |socket|
          socket.bind 'ipc://sink'
        end
      end
    end

    class Client
      def push(message)
        socket.send message
      end

      private

      def socket
        @socket ||= Flatware.socket(ZMQ::PUSH).tap do |socket|
          socket.connect 'ipc://sink'
        end
      end
    end
  end
end
