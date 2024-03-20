module Flatware
  module Sink
    class Signal
      def initialize(&on_interrupt)
        Thread.main[:signals] = Queue.new

        @on_interrupt = on_interrupt
      end

      def interruped?
        !signals.empty?
      end

      def listen
        Thread.new(&method(:handle_signals))

        ::Signal.trap('INT') { signals << :int }
        ::Signal.trap('CLD') { signals << :cld }

        self
      end

      def self.listen(&block)
        new(&block).listen
      end

      private

      def handle_signals
        puts signal_message(signals.pop)
        Process.waitall
        @on_interrupt.call
        puts 'done.'
        abort
      end

      def signal_message(signal)
        format(<<~MESSAGE, { cld: 'A worker died', int: 'Interrupted' }.fetch(signal))

          %s!

          Cleaning up. Please wait...
        MESSAGE
      end

      def signals
        Thread.main[:signals]
      end
    end
  end
end
