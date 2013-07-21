require 'cucumber/formatter/console'
require 'flatware/checkpoint'
require 'flatware/formatters/console'
module Flatware
  module Formatters
    class Console
      class Summary
        include ::Cucumber::Formatter::Console
        attr_reader :io, :steps, :scenarios

        def initialize(steps, scenarios=[], io=StringIO.new)
          @io = io
          @steps = steps
          @scenarios = scenarios
        end

        def summarize
          2.times { io.puts }
          print_steps :failed
          print_failed_scenarios scenarios
          print_counts 'scenario', scenarios
          print_counts 'step', steps
        end

        private

        def print_failed_scenarios(scenarios)
          return unless scenarios.any? &with_status(:failed)

          io.puts format_string "Failing Scenarios:", :failed
          scenarios.select(&with_status(:failed)).sort_by(&:file_colon_line).each do |scenario|
            io.puts format_string(scenario.file_colon_line, :failed) + format_string(" # Scenario: " + scenario.name, :comment)
          end
          io.puts
        end

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
          status_counts = STATUSES.map do |status|
            count = results.select(&with_status(status)).size
            format_string "#{count} #{status}", status if count > 0
          end.compact.join ", "

          " (#{status_counts})"
        end
      end
    end
  end
end
