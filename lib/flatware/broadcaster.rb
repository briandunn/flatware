# frozen_string_literal: true

module Flatware
  # sends messages to all formatters
  class Broadcaster
    FORMATTER_MESSAGES = %i[
      finished
      jobs
      message
      progress
      started
      summarize
      summarize_remaining
      worker_ready
    ].freeze

    attr_reader :formatters

    def initialize(formatters)
      @formatters = formatters
    end

    def method_missing(name, *args)
      return super unless FORMATTER_MESSAGES.include? name

      formatters.select { |formatter| formatter.respond_to? name }
                .each { |formatter| formatter.send name, *args }
    end

    def respond_to_missing?(name, _include_all)
      FORMATTER_MESSAGES.include? name
    end
  end
end
