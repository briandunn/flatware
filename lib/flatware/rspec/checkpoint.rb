# frozen_string_literal: true

require 'flatware/rspec/examples_notification'

module Flatware
  module RSpec
    class Checkpoint
      attr_reader :summary, :failures_notification

      def initialize(summary, failures_notification)
        @summary = summary
        @failures_notification = ExamplesNotification.new(
          failures_notification.failure_notifications
        )
      end

      def +(other)
        self.class.new(
          (summary + other.summary),
          (failures_notification + other.failures_notification)
        )
      end

      def failures?
        [
          summary.failure_count,
          summary.errors_outside_of_examples_count
        ].any?(&:positive?)
      end

      def failure_notifications
        failures_notification.failure_notifications
      end

      def fully_formatted_failed_examples(*args)
        failures_notification.fully_formatted_failed_examples(*args)
      end
    end
  end
end
