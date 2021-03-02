require 'rspec/core'
require 'flatware/rspec/marshalable/example'

module Flatware
  module RSpec
    module Marshalable
      class ExamplesNotification < ::RSpec::Core::Notifications::ExamplesNotification
        Reporter = Struct.new(:examples, :failed_examples, :pending_examples) do
          def self.from_rspec(reporter)
            new(*members.map { |member| reporter.public_send(member).map(&Example.method(:new)) })
          end

          def +(other)
            self.class.new(*zip(other).map { |a, b| a + b })
          end
        end

        attr_reader :reporter

        def self.from_rspec(rspec_notification)
          new Reporter.from_rspec(rspec_notification.instance_variable_get(:@reporter))
        end

        def +(other)
          self.class.new reporter + other.reporter
        end
      end
    end
  end
end
