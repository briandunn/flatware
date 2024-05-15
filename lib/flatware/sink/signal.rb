module Flatware
  module Sink
    class Signal
      Message = Struct.new(:message)

      attr_reader :formatter

      def initialize(formatter, &on_interrupt)
        @formatter = formatter
        Thread.main[:signals] = Queue.new

        @on_interrupt = on_interrupt
      end

      def listen
        Thread.new(&method(:handle_signals))

        ::Signal.trap('INT') { signals << :int }
        ::Signal.trap('CLD') do
          signals << :cld if child_failed?
        end

        self
      end

      def self.listen(formatter, &block)
        new(formatter, &block).listen
      end

      private

      def child_status
        _worker_pid, status = begin
          Process.wait2(-1, Process::WNOHANG)
        rescue Errno::ECHILD
          []
        end
        status
      end

      def child_statuses
        statuses = []
        loop do
          status = child_status
          return statuses unless status

          statuses << status
        end
      end

      def child_failed?
        child_statuses.any? { |status| !status.success? }
      end

      # TODO: handle second int
      def handle_signals
        signal_message(signals.pop) do
          Process.waitall # necessary? sink could wait.
          @on_interrupt.call
        end

        abort # necessary? sink counld do it.
      end

      def signal_message(signal)
        formatter.message(Message.new(format(<<~MESSAGE, { cld: 'A worker died', int: 'Interrupted' }.fetch(signal))))

          %s!

          Waiting for workers to finish their current jobs...
        MESSAGE

        yield

        formatter.message(Message.new('done.'))
      end

      def signals
        Thread.main[:signals]
      end
    end
  end
end
