require 'flatware'
require 'flatware/cucumber/formatter'
module Flatware
  class Sink
    class << self
      def push(message)
        client.push Marshal.dump message
      end

      def finished(job)
        push job
      end

      def start_server(jobs=Cucumber.jobs, out_stream=$stdout, error_stream=$stderr)
        Server.new(jobs, out_stream, error_stream).start
      end

      def client
        @client ||= Client.new
      end
    end

    class Server
      def initialize(jobs, out, error)
        @jobs, @out, @error = jobs, out, error
      end

      def start
        trap 'INT' do
          summarize
          summarize_remaining
        end

        before_firing { listen }
        Flatware.close
      end

      def listen
        until done?
          message = socket.recv
          case (result = Marshal.load message)
          when Result
            print result.progress
          when Checkpoint
            checkpoints << result
          when Job
            completed_jobs << result
            log "COMPLETED SCENARIO"
          else
            log "i don't know that message, bro."
          end
        end
        summarize
      rescue ZMQ::Error => e
        raise unless e.message == "Interrupted system call"
      end

      private

      attr_reader :out, :jobs

      def print(*args)
        out.print *args
      end

      def puts(*args)
        out.puts *args
      end

      def summarize
        steps = checkpoints.map(&:steps).flatten
        scenarios = checkpoints.map(&:scenarios).flatten
        Summary.new(steps, scenarios, out).summarize
      end

      def summarize_remaining
        return if remaining_work.empty?
        puts
        puts "The following features have not been run:"
        for job in remaining_work
          puts job.id
        end
      end

      def log(*args)
        Flatware.log *args
      end

      def before_firing(&block)
        die = Flatware.socket(ZMQ::PUB).tap do |socket|
          socket.bind 'ipc://die'
        end
        block.call
        die.send 'seppuku'
      end

      def checkpoints
        @checkpoints ||= []
      end

      def completed_jobs
        @completed_jobs ||= []
      end

      def done?
        log remaining_work
        remaining_work.empty?
      end

      def remaining_work
        jobs - completed_jobs
      end

      def fireable
        @fireable ||= Fireable.new
      end

      def socket
        @socket ||= Flatware.socket(ZMQ::PULL).tap do |socket|
          socket.bind 'ipc://sink'
        end
      end
    end

    class Client
      def push(message)
        socket.send message
      end

      private

      def socket
        @socket ||= Flatware.socket(ZMQ::PUSH).tap do |socket|
          socket.connect 'ipc://sink'
        end
      end
    end
  end
end
