require 'cucumber/formatter/console'
module Flatware
  class Summary
    include ::Cucumber::Formatter::Console
    attr_reader :io, :steps, :scenarios

    def initialize(checkpoints, io=StringIO.new)
      @io = io
      @steps = checkpoints.map(&:steps).flatten
      @scenarios = checkpoints.map(&:scenarios).flatten
    end

    def summarize
      2.times { io.puts }
      print_steps :failed
      print_counts 'scenario', scenarios
      print_counts 'step', steps
    end

    private

    def print_steps(status)
      print_elements steps.select(&with_status(status)), status, 'steps'
    end

    def print_counts(label, collection)
      io.puts pluralize(label, collection.size) + count_summary(collection)
    end

    def pluralize(word, number)
      "#{number} #{number == 1 ? word : word + 's'}"
    end

    def with_status(status)
      proc {|r| r.status == status}
    end

    def count_summary(results)
      return "" unless results.any?
      status_counts = Cucumber::STATUSES.map do |status|
        count = results.select(&with_status(status)).size
        format_string "#{count} #{status}", status if count > 0
      end.compact.join ", "

      " (#{status_counts})"
    end
  end
end
