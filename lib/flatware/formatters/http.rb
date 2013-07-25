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
        client.send_message steps: steps, scenarios: scenarios
      end

      def summarize_remaining(jobs)
        client.send_message remaining: jobs
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

