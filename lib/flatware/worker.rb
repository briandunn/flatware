module Flatware
  class Worker
    class << self

      def context
        @context ||= ZMQ::Context.new 1
      end

      def in_context(&block)
        yield context
        context.close
      end

      def listen!
        in_context do |context|

          dispatch = context.socket ZMQ::REQ
          dispatch.connect 'ipc://dispatch'

          die = context.socket ZMQ::SUB
          die.connect 'ipc://die'
          die.setsockopt ZMQ::SUBSCRIBE, ''

          dispatch.send 'hi'

          quit = false
          while !quit && (ready = ZMQ.select([dispatch, die]))
            messages = ready.flatten.compact.map(&:recv)
            for message in messages
              if message == 'seppuku'
                quit = true
              else
                out = err = StringIO.new
                Cucumber.run message, out, err
                result = out.tap(&:rewind).read
                dispatch.send result
              end
            end
          end
          dispatch.close
          die.close
        end
      end
    end
  end
end
