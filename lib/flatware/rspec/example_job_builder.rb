# frozen_string_literal: true

require 'rspec/core/sandbox'

module Flatware
  module RSpec
    # groups examples into one job per worker.
    # reads from persisted example statuses, if available,
    # and attempts to ballence the jobs accordingly.
    class ExampleJobBuilder
      attr_reader :args, :workers

      def initialize(args, workers:)
        @args = args
        @workers = workers

        load_configuration_and_examples
      end

      def jobs
        timed_examples, untimed_examples = timed_and_untimed_examples
        buckets = Array.new([@examples_to_run.size, workers].min) { Bucket.new }

        balance_jobs(
          buckets: buckets,
          timed_examples: timed_examples,
          untimed_examples: untimed_examples
        )
      end

      private

      def balance_jobs(buckets:, timed_examples:, untimed_examples:)
        timed_examples.each do |(example_id, time)|
          buckets.min_by(&:runtime).add_example(example_id, time)
        end

        untimed_examples.each_with_index do |example_id, index|
          offset = (timed_examples.size + index) % buckets.size
          buckets[offset].add_example(example_id)
        end

        buckets.map { |bucket| Job.new(bucket.examples, args) }
      end

      def timed_and_untimed_examples
        timed_examples = []
        untimed_examples = []

        @examples_to_run.each do |example_id|
          if (time = example_runtimes[example_id])
            timed_examples << [example_id, time]
          else
            untimed_examples << example_id
          end
        end

        [timed_examples.sort_by! { |(_id, time)| -time }, untimed_examples]
      end

      def load_persisted_example_statuses
        ::RSpec::Core::ExampleStatusPersister.load_from(@example_status_persistence_file_path || '')
      end

      def example_runtimes
        @example_runtimes ||= load_persisted_example_statuses.each_with_object({}) do |status_entry, runtimes|
          next unless status_entry.fetch(:status) =~ /pass/i

          runtimes[status_entry[:example_id]] = status_entry[:run_time].to_f
        end
      end

      def load_configuration_and_examples
        configuration = ::RSpec.configuration
        configuration.define_singleton_method(:command) { 'rspec' }

        ::RSpec::Core::ConfigurationOptions.new(args).configure(configuration)

        @example_status_persistence_file_path = configuration.example_status_persistence_file_path

        # Load spec files in a fork to avoid polluting the parent process,
        # otherwise the actual execution will return warnings for redefining constants
        # and shared example groups.
        @examples_to_run = within_forked_process { load_examples_to_run(configuration) }
      end

      def within_forked_process
        reader, writer = IO.pipe(binmode: true)

        fork do
          reader.close
          $stdout = File.new(File::NULL, 'w')

          writer.write Marshal.dump(yield)
        end

        writer.close
        Marshal.load(reader.gets) # rubocop:disable Security/MarshalLoad
      end

      def load_examples_to_run(configuration)
        configuration.load_spec_files

        # If there's an error loading spec files, exit immediately.
        exit(configuration.failure_exit_code) if ::RSpec.world.wants_to_quit

        ::RSpec.world.ordered_example_groups.flat_map(&:descendants).flat_map(&:filtered_examples).map(&:id)
      end

      class Bucket
        attr_reader :examples, :runtime

        def initialize
          @examples = []
          @runtime = 0
        end

        def add_example(example_id, runtime = 0)
          @examples << example_id
          @runtime += runtime
        end
      end
    end
  end
end
