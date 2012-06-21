module Flatware
  class Dispatcher
    class << self

      def dispatch
        @dispatch ||= Flatware.socket(ZMQ::REP).tap do |socket|
          socket.bind 'ipc://dispatch'
        end
      end

      def die
        @die ||= Flatware.socket(ZMQ::PUB).tap do |socket|
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
          end
          feature = features.pop
          if feature
            dispatch.send feature
            dispatched += 1
            log "Not yet dispatched: #{features.length}"
            log "       In progress: #{dispatched}"
          else
            dispatch.send 'seppuku'
          end
          break if dispatched == 0
        end

        die!
        Flatware.close
      end

      private

      def log(*args)
        Flatware.log *args
      end

      def die!
        die.send 'seppuku'
      end
    end
  end
end
