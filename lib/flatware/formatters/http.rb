require 'net/http'
require 'pathname'

module Flatware
  module Formatters
    class Http
      attr_reader :out, :client, :server_pid
      def initialize(out, err)
        @out = out
        @client = Client.new
      end

      def jobs(jobs)
        client.send_message [:jobs, jobs.map {|job| {id: job.id}}]
      end

      def started(job)
        client.send_message [:started, job: job.id, worker: job.worker]
      end

      def finished(job)
        client.send_message [:finished, job: job.id, worker: job.worker]
      end

      def progress(result)
        client.send_message [:progress, status: result.progress, worker: result.worker]
      end

      def summarize(steps, scenarios)
        client.send_message [
          :summarize, {
            steps: steps.map(&method(:step_as_json)),
            scenarios: scenarios.map(&method(:scenario_as_json))
          }
        ]
      end

      private

      def step_as_json(step)
        { status: step.status }.tap do |h|
          h.merge(exception: {
            class: step.exception.class,
            message: step.exception.message,
            backtrace: step.exception.backtrace
          }) if step.exception
        end
      end

      def scenario_as_json(scenario)
        {
          status: scenario.status,
          file_colon_line: scenario.file_colon_line,
          name: scenario.name
        }
      end

      class Client
        attr_reader :uri
        include Net

        def initialize
          @uri = URI ENV['FLATWARE_URL']
        end

        def send_message(message)
          send_request uri.path, JSON.dump(message)
        end

        private

        def send_request(path, body=nil)
          req = HTTP::Post.new path
          req.body = body
          res = HTTP.start uri.hostname, uri.port do |http|
            http.request req
          end
        end
      end
    end
  end
end

