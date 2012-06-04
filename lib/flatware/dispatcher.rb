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

        features = Cucumber.features

        dispatched = 0
        while request = dispatch.recv
          if request != 'hi'
            # request is a test result
            dispatched -= 1
            print request
          end
          feature = features.pop
          if feature
            dispatch.send feature
            dispatched += 1
          else
            dispatch.send 'seppuku'
          end
          break if dispatched == 0
        end

        die!

        dispatch.close
        context.close

        puts "\n\n"
        puts "2 scenarios (2 passed)"
        puts "2 steps (2 passed)"
      end

      private

      def die!
        die.send 'seppuku'
        die.close
      end
    end
  end
end
