module Flatware
  class Dispatcher
    class << self

      def context
        @context ||= ZMQ::Context.new 1
      end

      def dispatch
        @dispatch ||= context.socket(ZMQ::REP).tap do |socket|
          socket.bind 'ipc://dispatch'
        end
      end

      def die
        @die ||= context.socket(ZMQ::PUB).tap do |socket|
          socket.bind 'ipc://die'
        end
      end

      def dispatch!
        die
        Sink.start_server

        features = Cucumber.features

        dispatched = 0

        while request = dispatch.recv
          if request != 'hi'
            # request is a test result
            dispatched -= 1
          end
          feature = features.pop
          if feature
            dispatch.send feature
            dispatched += 1
            puts "Not yet dispatched: #{features.length}"
            puts "       In progress: #{dispatched}"
          else
            dispatch.send 'seppuku'
          end
          break if dispatched == 0
        end

        die!

        dispatch.close
        context.close
      end

      private

      def die!
        die.send 'seppuku'
        die.close
      end
    end
  end
end
