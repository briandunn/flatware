# frozen_string_literal: true

require 'forwardable'
require 'flatware/rspec/marshalable'

module Flatware
  module RSpec
    ##
    # Marshalable container for the run details from a worker.
    # Can be added to other checkpoints to create a final run summary.
    class Checkpoint
      extend Forwardable

      def_delegator :summary, :failures?
      def_delegators :failures_notification, :fully_formatted_failed_examples, :failure_notifications
      def_delegators :pending_notification, :fully_formatted_pending_examples, :pending_examples

      EVENTS = %i[
        deprecation
        dump_failures
        dump_pending
        dump_profile
        dump_summary
      ].freeze

      attr_reader :events

      def initialize(events = {})
        @events = { deprecation: [] }.merge(events)
      end

      def self.listen_for(event, &block)
        define_method(event) do |notification|
          instance_exec(Marshalable.for_event(event).from_rspec(notification), &block)
        end
      end

      (EVENTS - %i[deprecation]).each do |event|
        listen_for(event) do |notification|
          events[event] = notification
        end
      end

      listen_for(:deprecation) do |deprecation|
        events[:deprecation] << deprecation
      end

      def +(other)
        self.class.new(events.merge(other.events) { |_, event, other_event| event + other_event })
      end

      def summary
        events.fetch(:dump_summary)
      end

      def deprecations
        events.fetch(:deprecation)
      end

      def profile
        events[:dump_profile]
      end

      private

      def failures_notification
        events.fetch(:dump_failures)
      end

      def pending_notification
        events.fetch(:dump_pending)
      end
    end
  end
end
