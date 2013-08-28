require 'flatware'
module Flatware
  class Sink
    PORT = 'ipc://sink'
    class << self
      def push(message)
        client.push message
      end

      def finished(job)
        push job
      end

      def start_server(*args)
        Server.new(*args).start
      end

      def client
        @client ||= Client.new
      end
    end

    class Server
      def initialize(jobs, formatter, options={})
        @jobs, @formatter = jobs, formatter
        options = {fail_fast: false}.merge options
        @fail_fast = options[:fail_fast]
      end

      def start
        trap 'INT' do
          checkpoint_handler.summarize
          summarize_remaining
          exit 1
        end

        before_firing { listen }
        Flatware.close
      end

      def checkpoint_handler
        @checkpoint_handler ||= CheckpointHandler.new(formatter, fail_fast?)
      end

      def listen
        until done?
          result = socket.recv
          case result
          when Result
            formatter.result result
          when Checkpoint
            checkpoint_handler.handle! result
          when Job
            completed_jobs << result
          end
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

      def log(*args)
        Flatware.log *args
      end

      def before_firing(&block)
        Flatware::Fireable::bind
        block.call
        Flatware::Fireable::kill
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

      def fireable
        @fireable ||= Fireable.new
      end

      def socket
        @socket ||= Flatware.socket(ZMQ::PULL, bind: PORT)
      end
    end

    class Client
      def push(message)
        socket.send message
      end

      private

      def socket
        @socket ||= Flatware.socket(ZMQ::PUSH, connect: PORT)
      end
    end
  end
end
