module Flatware
  module RSpec
    ProgressMessage = Struct.new(:progress)

    class SerializedExampleGroup
      attr_reader :example_group, :parent_groups, :metadata

      def initialize(example_group)
        @example_group = example_group.to_s
        @metadata      = example_group.metadata.dup
        @metadata[:example_group_block] = nil
        @parent_groups = serialize_parent_groups(example_group.parent_groups)
      end

      def serialize_parent_groups(example_groups)
        example_groups.map do |group|
          self.class.new(group) unless group.to_s == example_group
        end.compact
      end
    end

    class SerializedExample
      attr_reader :execution_result, :full_description, :file_path, :example_group, :metadata
      def initialize(execution_result, full_description, file_path, example_group, metadata)
        @metadata = metadata
        @metadata[:example_group_block] = nil
        @execution_result, @full_description, @file_path, @example_group = execution_result, full_description, file_path, SerializedExampleGroup.new(example_group)
      end
    end

    class Checkpoint
      attr_reader :summary, :failed_examples

      def initialize(summary, failed_examples)
        @summary, @failed_examples = summary, failed_examples.map(&method(:serialize_example))
      end

      def failures?
        summary.failure_count > 0
      end

      private

      def serialize_example(example)
        SerializedExample.new example.execution_result, example.full_description, example.file_path, example.example_group, example.metadata.dup
      end
    end

    class Formatter
      attr_reader :summary, :failed_examples

      def initialize(stdout=nil)
        @failed_examples = []
      end

      def example_passed(example)
        send_progress :passed
      end

      def example_failed(example)
        @failed_examples << example
        send_progress :failed
      end

      def example_pending(example)
        send_progress :pending
      end

      def dump_summary(duration, example_count, failure_count, pending_count)
        @summary = Summary.new duration, example_count, failure_count, pending_count
      end

      def close
        Sink::client.checkpoint Checkpoint.new(summary, failed_examples)
      end

      private

      def send_progress(status)
        Sink::client.progress ProgressMessage.new status
      end
    end
  end
end
