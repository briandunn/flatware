module Flatware
  class Dispatcher
    class << self

      def dispatch
        @dispatch ||= Flatware.socket(ZMQ::REP).tap do |socket|
          socket.bind 'ipc://dispatch'
        end
      end

      def dispatch!
        features = Cucumber.features

        dispatched = 0

        fireable.until_fired dispatch do |request|
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
        end
      end

      private

      def log(*args)
        Flatware.log *args
      end

      def fireable
        @fireable ||= Fireable.new
      end
    end
  end
end
