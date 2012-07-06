require 'flatware'
require 'flatware/cucumber/formatter'
module Flatware
  class Sink
    CompletedJob = Struct.new(:id)
    class << self
      def push(message)
        client.push Marshal.dump message
      end

      def finished(job)
        push CompletedJob.new(job)
      end

      def start_server
        Server.start
      end

      def client
        @client ||= Client.new
      end
    end

    module Server
      extend self

      def start
        before_firing { listen }
        Flatware.close
      end

      def listen
        until done?
          message = socket.recv
          log 'printing'
          case (result = Marshal.load message)
          when Result
            print result.progress
            steps.push *result.steps
          when CompletedJob
            completed_scenarios << result
            log "COMPLETED SCENARIO"
          else
            log "i don't know that message, bro."
          end
        end
        summarize
      end

      private

      def summarize
        Summary.new(steps, $stdout).summarize
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

      def steps
        @steps ||= []
      end

      def completed_scenarios
        @completed_scenarios ||= []
      end

      def done?
        log remaining_work
        remaining_work.empty?
      end

      def remaining_work
        Cucumber.features - completed_scenarios.map(&:id)
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
