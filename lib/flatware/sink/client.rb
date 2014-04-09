require 'flatware/socket'
module Flatware
  module Sink
    extend self
    attr_accessor :client

    class Client
      def initialize(sink_endpoint)
        @socket = Flatware.socket ZMQ::PUSH, connect: sink_endpoint
      end

      def method_missing(message, content)
         push message.to_sym, content
      end

      def push(message, content=nil)
        @socket.send [message, content].compact
      end
    end
  end
end
