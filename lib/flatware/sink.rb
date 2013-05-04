require 'flatware'
require 'flatware/cucumber/formatter'
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

      def start_server(job_cue=Cucumber.jobs, out_stream=$stdout, error_stream=$stderr)
        Server.new(job_cue, out_stream, error_stream).start
      end

      def client
        @client ||= Client.new
      end
    end

    class Server

      def initialize(job_cue, out, error)
        @job_cue, @out, @error = job_cue, out, error
      end

      def start
        trap 'INT' do
          summarize_activity
          exit 1
        end

        before_firing do
          listen
          summarize_activity
        end
        Flatware.close
      end

      def listen
        loop do
          return unless job_dispatched
          # handle_messages
        end
      rescue Error => e
        raise unless e.message == "Interrupted system call"
      end

      private

      attr_reader :out, :job_cue

      def print(*args)
        out.print *args
      end

      def puts(*args)
        out.puts *args
      end

      def job_dispatched
        p job_cue
        # this should ideally use the dispatcher object
        # to pop a job off from the cue and send it
        # over the wire to a worker.
        job_cue.dispatch_next_job
      end

      def summarize_activity
        summarize_completed
        summarize_remaining
      end

      def summarize_completed
        steps = checkpoints.map(&:steps).flatten
        scenarios = checkpoints.map(&:scenarios).flatten
        Summary.new(steps, scenarios, out).summarize
      end

      def summarize_remaining
        return if job_cue.empty?
        puts
        puts "The following features have not been run:"
        for job in job_cue.remaining_work
          puts job.id
        end
      end

      def log(*args)
        Flatware.log *args
      end

      def before_firing(&block)
        Flatware::Fireable::bind
        block.call
        Flatware::Fireable::kill
      end

      def checkpoints
        @checkpoints ||= []
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
