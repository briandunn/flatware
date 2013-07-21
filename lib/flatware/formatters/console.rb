require 'flatware/formatters/console/summary'
module Flatware
  module Formatters
    class Console
      attr_reader :out, :err

      def initialize(stdout, stderr)
        @out, @err = stdout, stderr
      end

      def result(result)
        out.print result.progress
      end

      def summarize(steps, scenarios)
        Summary.new(steps, scenarios, out).summarize
      end

      def summarize_remaining(remaining_jobs)
        out.puts
        out.puts "The following features have not been run:"
        for job in remaining_jobs
          out.puts job.id
        end
      end
    end
  end
end
