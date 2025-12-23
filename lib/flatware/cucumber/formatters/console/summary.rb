require 'cucumber/formatter/console'
require 'flatware/cucumber/formatters/console'

module Flatware
  module Cucumber
    module Formatters
      class Console
        class Summary
          include ::Cucumber::Formatter::Console

          attr_reader :io, :steps, :scenarios

          def initialize(steps, scenarios = [], io = StringIO.new)
            @io = io
            @steps = steps
            @scenarios = scenarios
          end

          def summarize
            2.times { io.puts }
            print_failures(steps, 'step')
            print_failures(scenarios.select(&:failed_outside_step?), 'scenario')
            print_failed_scenarios scenarios
            print_counts 'scenario', scenarios
            print_counts 'step', steps
          end

          private

          def print_failed_scenarios(scenarios)
            failed_scenarios = scenarios.select(&with_status(:failed))
            return if failed_scenarios.empty?

            io.puts format_string 'Failing Scenarios:', :failed
            failed_scenarios
              .sort_by(&:file_colon_line)
              .map(&method(:to_failed_scenario_line))
              .each(&io.method(:puts))
            io.puts
          end

          def to_failed_scenario_line(scenario)
            [
              [scenario.file_colon_line, :failed],
              ["# Scenario: #{scenario.name}", :comment]
            ].map do |string, format|
              format_string string, format
            end.join(' ')
          end

          def print_failures(collection, label)
            failures = collection.select(&with_status(:failed))
            print_elements failures, :failed, pluralize(label, failures.size)
          end

          def print_counts(label, collection)
            io.puts(
              pluralize(label, collection.size) + count_summary(collection)
            )
          end

          def pluralize(word, number)
            "#{number} #{number == 1 ? word : "#{word}s"}"
          end

          def with_status(status)
            proc { |r| r.status == status }
          end

          def count_summary(results)
            return '' unless results.any?

            status_counts = STATUSES.map do |status|
              count = results.select(&with_status(status)).size
              format_string "#{count} #{status}", status if count.positive?
            end.compact.join ', '

            " (#{status_counts})"
          end
        end
      end
    end
  end
end
