require 'flatware/socket'
module Flatware
  module Sink
    extend self
    attr_accessor :client

    class Client
      attr_reader :die

      def initialize(sink_endpoint)
        @socket = Flatware.socket ZMQ::PUSH, connect: sink_endpoint
        @die = Thread.current[:die] or begin
          die = Flatware.socket(ZMQ::SUB, connect: 'ipc://die')
          die.setsockopt ZMQ::SUBSCRIBE, ''
        end
      end

      %w[finished started progress checkpoint].each do |message|
        define_method message do |content|
          push [message.to_sym, content]
        end
      end

      private

      def push(message)
        if die.recv(block: false) == 'seppuku'
          Flatware.close
          exit(0)
        else
          @socket.send message
        end
      end
    end
  end
end
