# frozen_string_literal: true

module Flatware
  # sends messages to all formatters
  class Broadcaster
    attr_reader :formatters

    def initialize(formatters)
      @formatters = formatters
    end

    def method_missing(name, *args)
      responding_formatters = formatters.select do |formatter|
        formatter.respond_to? name
      end

      return super unless responding_formatters.any?

      responding_formatters.each do |formatter|
        formatter.send name, *args
      end
    end

    def respond_to_missing?(name, _include_all)
      formatters.any? do |formatter|
        formatter.respond_to? name
      end
    end
  end
end
