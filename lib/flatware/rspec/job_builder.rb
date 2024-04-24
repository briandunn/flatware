# frozen_string_literal: true

require 'forwardable'

module Flatware
  module RSpec
    # groups spec files into one job per worker.
    # reads from persisted example statuses, if available,
    # and attempts to ballence the jobs accordingly.
    class JobBuilder
      extend Forwardable
      attr_reader :args, :workers, :configuration, :duration_provider

      def_delegators :configuration, :files_to_run

      def initialize(args, workers:, duration_provider:)
        @args = args
        @workers = workers
        @duration_provider = duration_provider

        @configuration = ::RSpec.configuration
        configuration.define_singleton_method(:command) { 'rspec' }

        ::RSpec::Core::ConfigurationOptions.new(args).configure(@configuration)
      end

      def jobs
        timed_files, untimed_files = timed_and_untimed_files(
          duration_provider.seconds_per_file
        )

        balance_jobs(
          bucket_count: [files_to_run.size, workers].min,
          timed_files: timed_files,
          untimed_files: untimed_files
        )
      end

      private

      def balance_jobs(bucket_count:, timed_files:, untimed_files:)
        balance_by(bucket_count, timed_files, &:last)
          .map { |bucket| bucket.map(&:first) }
          .zip(
            round_robin(bucket_count, untimed_files)
          ).map(&:flatten)
          .map { |files| Job.new(files, args) }
      end

      def timed_and_untimed_files(seconds_per_file)
        files_to_run
          .map(&method(:normalize_path))
          .reduce([[], []]) do |(timed, untimed), file|
          if (time = seconds_per_file[file])
            [timed + [[file, time]], untimed]
          else
            [timed, untimed + [file]]
          end
        end
      end

      def normalize_path(path)
        ::RSpec::Core::Metadata.relative_path(File.expand_path(path))
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
