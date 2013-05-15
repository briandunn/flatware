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

      def start_server(*args)
        Server.new(*args).start
      end

      def client
        @client ||= Client.new
      end
    end

    class Server
      def initialize(jobs, out=$stdout, error=$stderr, fail_fast=false)
        @jobs, @out, @error, @fail_fast = jobs, out, error, fail_fast
      end

      def start
        trap 'INT' do
          summarize
          summarize_remaining
          exit 1
        end

        before_firing { listen }
        Flatware.close
      end

      def listen
        until done?
          result = socket.recv
          case result
          when Result
            print result.progress
          when Checkpoint
            checkpoints << result
            if result.failures? && fail_fast?
              log "sink is firing everybody!"
              Fireable::kill
              summarize
              return
            end
          when Job
            completed_jobs << result
            log "COMPLETED SCENARIO"
          else
            log "i don't know that message, bro.", message
          end
        end
        summarize
      rescue Error => e
        raise unless e.message == "Interrupted system call"
      end

      private

      def fail_fast?
        @fail_fast
      end

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
        Flatware::Fireable::bind
        block.call
        Flatware::Fireable::kill
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
