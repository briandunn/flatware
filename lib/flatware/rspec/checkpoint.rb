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

      DUMP_EVENTS = %i[
        dump_failures
        dump_pending
        dump_profile
        dump_summary
      ].freeze

      EVENTS = (DUMP_EVENTS + %i[seed deprecation]).freeze

      attr_reader :events, :worker_number

      def initialize(worker_number: nil, reruns: nil, **events)
        @events = { deprecation: [] }.merge(events)
        @reruns = reruns
        @worker_number = worker_number
      end

      def self.listen_for(event, &block)
        define_method(event) do |notification|
          instance_exec(Marshalable.for_event(event).from_rspec(notification), &block)
        end
      end

      DUMP_EVENTS.each do |event|
        listen_for(event) do |notification|
          events[event] = notification
        end
      end

      listen_for(:deprecation) do |deprecation|
        events[:deprecation] << deprecation
      end
      listen_for(:seed) do |message|
        @seed = message
      end

      def +(other)
        merged_events = events.merge(other.events) { |_, event, other_event| event + other_event }
        self.class.new(**merged_events, reruns: reruns.merge(other.reruns))
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

      def reruns
        @reruns ||= reruns? ? { worker_number => { seed: @seed.seed, examples: summary.example_paths } } : {}
      end

      private

      def reruns?
        @seed&.seed_used? && failures?
      end

      def failures_notification
        events.fetch(:dump_failures)
      end

      def pending_notification
        events.fetch(:dump_pending)
      end
    end
  end
end
