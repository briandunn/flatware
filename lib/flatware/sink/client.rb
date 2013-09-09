require 'flatware/socket'
module Flatware
  module Sink
    extend self
    attr_accessor :client

    class Client

      attr_reader :socket, :fireable

      def initialize(sink_endpoint, fireable)
        @socket   = Flatware.socket ZMQ::PUSH, connect: sink_endpoint
        @fireable = fireable
      end

      %w[finished started progress checkpoint].each do |message|
        define_method message do |content|
          push [message.to_sym, content]
        end
      end

      private

      def push(message)
        fireable.ensure_employment!
        socket.send message
      end
    end
  end
end
