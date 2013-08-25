require 'flatware'
module Flatware
  class Sink
    RESULT_PORT   = 'ipc://sink'
    DISPATCH_PORT = 'ipc://dispatch'
    class << self

      def socket
        @socket ||= Flatware.socket(ZMQ::PUSH, connect: RESULT_PORT)
      end

      private
      def push(message)
        socket.send message
      end
    end

    %w[finished progress checkpoint].each do |message|
      define_singleton_method message do |content|
        push [message.to_sym, content]
      end
    end

    class Server
      attr_reader :sockets

      def initialize(jobs, formatter, options={})
        @jobs, @formatter = jobs, formatter
        @queue = jobs.dup

        options = {fail_fast: false}.merge options
        @fail_fast = options[:fail_fast]
        results  = Flatware.socket(ZMQ::PULL, bind: RESULT_PORT)
        dispatch = Flatware.socket(ZMQ::REP,  bind: DISPATCH_PORT)
        @sockets = Poller.new results, dispatch
      end

      def start
        trap 'INT' do
          checkpoint_handler.summarize
          summarize_remaining
          exit 1
        end

        Fireable::bind
        listen
        Fireable::kill
        Flatware.close
      end

      def checkpoint_handler
        @checkpoint_handler ||= CheckpointHandler.new(formatter, fail_fast?)
      end

      def listen
        workers = []
        sockets.each do |socket|
          message, content = socket.recv
          case message
          when :ready
            p workers
            workers.push content
            if job = @queue.pop
              socket.send [:job, job]
            else
              socket.send [:seppuku]
              workers.delete content
            end
          when :checkpoint
            checkpoint_handler.handle! content
          when :finished
            completed_jobs << content
            formatter.finished content
          else
            formatter.send message, content
          end
          break if workers.empty? && done?
        end
        checkpoint_handler.summarize
        exit 1 if checkpoint_handler.had_failures?
      rescue Error => e
        raise unless e.message == "Interrupted system call"
      end

      private

      def fail_fast?
        @fail_fast
      end

      attr_reader :jobs, :formatter

      def summarize_remaining
        return if remaining_work.empty?
        formatter.summarize_remaining remaining_work
      end

      def completed_jobs
        @completed_jobs ||= []
      end

      def done?
        remaining_work.empty? || checkpoint_handler.done?
      end

      def remaining_work
        jobs - completed_jobs
      end
    end
  end
end
