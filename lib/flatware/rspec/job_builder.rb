# frozen_string_literal: true

module Flatware
  module RSpec
    class JobBuilder
      attr_reader :args, :workers, :configuration

      def initialize(args, workers:)
        @args = args
        @workers = workers

        @configuration = ::RSpec.configuration
        def configuration.command
          'rspec'
        end

        ::RSpec::Core::ConfigurationOptions.new(args).configure(@configuration)
      end

      def jobs
        to_run = configuration
                 .files_to_run
                 .uniq.map do |file|
          ::RSpec::Core::Metadata.relative_path(File.expand_path(file))
        end

        bucket_count = [to_run.size, workers].min

        acc = equal_time_buckets(bucket_count)
              .each_with_object(buckets: [], unbucketed: to_run) do |bucket, acc|
          common = (bucket & acc[:unbucketed])
          acc[:buckets] << common
          acc[:unbucketed] = acc[:unbucketed] - common
        end

        # round robin the rest
        acc[:unbucketed]
          .each_with_index
          .each_with_object(acc[:buckets]) do |(entry, i), buckets|
          buckets[i % buckets.size] << entry
        end.map do |files|
          Job.new(files, args)
        end
      end

      private

      def seconds_per_file
        persisted_example_statuses.select { |status:, **| status =~ /passed/i }.map do |example_id:, run_time:, **|
          seconds = run_time.match(/\d+(\.\d+)?/).to_s.to_f
          file_name = ::RSpec::Core::Example.parse_id(example_id).first
          { seconds: seconds, file_name: file_name }
        end.reduce(Hash.new(0)) do |times, file_name:, seconds:|
          times.merge(file_name => seconds) { |_, old, new| old + new }
        end
      end

      def persisted_example_statuses
        ::RSpec::Core::ExampleStatusPersister.load_from(
          configuration.example_status_persistence_file_path || ''
        )
      end

      def equal_time_buckets(bucket_count)
        # find the bucket with the smallest sum and add it there
        buckets = seconds_per_file
                  .to_a
                  .sort_by(&:last)
                  .reverse
                  .each_with_object(Array.new(bucket_count) { [] }) do |entry, groups|
          groups.min_by do |group|
            group.map(&:last).reduce(:+) || 0
          end.push(entry)
        end

        buckets.map do |bucket|
          bucket.map(&:first)
        end
      end
    end
  end
end
