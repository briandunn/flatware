# frozen_string_literal: true

require 'forwardable'

module Flatware
  module RSpec
    module DurationProviders
      class ExampleStatusesProvider
        extend Forwardable
        attr_reader :configuration

        def_delegators :configuration, :example_status_persistence_file_path

        def initialize(configuration: ::RSpec.configuration)
          @configuration = configuration
        end

        def seconds_per_file
          sum_seconds(load_persisted_example_statuses)
        end

        private

        def load_persisted_example_statuses
          ::RSpec::Core::ExampleStatusPersister.load_from(
            example_status_persistence_file_path || ''
          )
        end

        def sum_seconds(statuses)
          statuses.select(&passing)
                  .map { |example| parse_example(**example) }
                  .reduce({}) do |times, example|
            times.merge(
              example.fetch(:file_name) => example.fetch(:seconds)
            ) do |_, old = 0, new|
              old + new
            end
          end
        end

        def passing
          ->(example) { example.fetch(:status) =~ /pass/i }
        end

        def parse_example(example_id:, run_time:, **)
          seconds = run_time.match(/\d+(\.\d+)?/).to_s.to_f
          file_name = ::RSpec::Core::Example.parse_id(example_id).first
          { seconds: seconds, file_name: file_name }
        end
      end
    end
  end
end
