require 'rspec/core'
require 'flatware/rspec/marshalable/example'

module Flatware
  module RSpec
    module Marshalable
      class ExampleNotification < ::RSpec::Core::Notifications::ExampleNotification
        def self.from_rspec(rspec_notification)
          new(Example.new(rspec_notification.example))
        end

        def fully_formatted(failure_number, colorizer = ::RSpec::Core::Formatters::ConsoleCodes)
          return if example.execution_result.status != :failed

          @exception_presenter ||= ::RSpec::Core::Formatters::ExceptionPresenter::Factory.new(example).build
          @exception_presenter.fully_formatted(failure_number, colorizer)
        end
      end
    end
  end
end
