require 'drb/drb'

module Flatware
  module Sink
    extend self
    attr_accessor :client

    class Client
      def initialize(sink_endpoint)
        @sink = DRbObject.new_with_uri sink_endpoint
      end

      %w[ready finished started progress checkpoint].each do |message|
        define_method message do |content|
          push [message.to_sym, content]
        end
      end

      private

      def push(message)
        @sink.send message
      end
    end
  end
end
