require 'drb/drb'

module Flatware
  module Sink
    module_function

    attr_accessor :client

    class Client
      def initialize(sink_endpoint)
        @sink = DRbObject.new_with_uri sink_endpoint
      end

      %w[ready finished started progress message checkpoint].each do |message|
        define_method message do |content|
          push [message.to_sym, content]
        end
      end

      private

      def push(message)
        @sink.public_send message
      end
    end
  end
end
