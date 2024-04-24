# frozen_string_literal: true

require 'flatware/rspec/duration_providers/example_statuses_provider'

module Flatware
  module RSpec
    module DurationProviders
      module_function

      def lookup(provider)
        const_get("#{classify(provider)}Provider").new
      end

      def classify(underscore_name)
        underscore_name.to_s.split('_').map(&:capitalize).join
      end

      private_class_method :classify
    end
  end
end
