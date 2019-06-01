# frozen_string_literal: true

module Flatware
  module RSpec
    # groups spec files into one job per worker.
    # reads from persisted example statuses, if available,
    # and attempts to ballence the jobs accordingly.
    class JobBuilder
      extend Forwardable
      attr_reader :args, :workers, :configuration
      def_delegators(
        :configuration,
        :files_to_run,
        :example_status_persistence_file_path
      )

      def initialize(args, workers:)
        @args = args
        @workers = workers

        @configuration = ::RSpec.configuration
        configuration.define_singleton_method(:command) { 'rspec' }

        ::RSpec::Core::ConfigurationOptions.new(args).configure(@configuration)
      end

      def jobs
        bucket_count = [files_to_run.size, workers].min

        seconds_per_file = load_persisted_example_statuses
                           .select(&passing)
                           .map(&parse_example)
                           .reduce({}, &sum_by_example_file)

        timed_files, untimed_files = files_to_run
                                     .map(&method(:normalize_path))
                                     .reduce(
                                       [[], []]
                                     ) do |(timed, untimed), file|
          if (time = seconds_per_file[file])
            [timed.append([file, time]), untimed]
          else
            [timed, untimed.append(file)]
          end
        end

        balance_by(bucket_count, timed_files, &:last)
          .map { |bucket| bucket.map(&:first) }
          .zip(
            round_robin(bucket_count, untimed_files)
          ).map(&:flatten)
          .map do |files|
          Job.new(files, args)
        end
      end

      private

      def normalize_path(path)
        ::RSpec::Core::Metadata.relative_path(File.expand_path(path))
      end

      def load_persisted_example_statuses
        ::RSpec::Core::ExampleStatusPersister.load_from(
          example_status_persistence_file_path || ''
        )
      end

      def sum_by_example_file
        lambda do |times, file_name:, seconds:|
          times.merge(file_name => seconds) { |_, old = 0, new| old + new }
        end
      end

      def passing
        ->(status:, **) { status =~ /pass/i }
      end

      def parse_example
        lambda do |example_id:, run_time:, **|
          seconds = run_time.match(/\d+(\.\d+)?/).to_s.to_f
          file_name = ::RSpec::Core::Example.parse_id(example_id).first
          { seconds: seconds, file_name: file_name }
        end
      end

      def round_robin(count, items)
        Array.new(count) { [] }.tap do |groups|
          items.each_with_index do |entry, i|
            groups[i % count] << entry
          end
        end
      end

      def balance_by(count, items, &block)
        # find the group with the smallest sum and add it there
        Array.new(count) { [] }.tap do |groups|
          items
            .sort_by(&block)
            .reverse
            .each do |entry|
            groups.min_by do |group|
              group.map(&block).reduce(:+) || 0
            end.push(entry)
          end
        end
      end
    end
  end
end
