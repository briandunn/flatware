require 'flatware/socket'
module Flatware
  module Sink
    extend self
    attr_accessor :client

    class Client
      def initialize(sink_endpoint)
        @socket = Flatware.socket ZMQ::PUSH, connect: sink_endpoint
      end

      %w[finished started progress checkpoint].each do |message|
        define_method message do |content|
          push [message.to_sym, content]
        end
      end

      private

      def push(message)
        @socket.send message
      end
    end
  end
end
