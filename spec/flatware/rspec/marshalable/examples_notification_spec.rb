require 'spec_helper'
require 'flatware/rspec/marshalable/examples_notification'

describe Flatware::RSpec::Marshalable::ExamplesNotification do
  it 'can be added together' do
    failed_example = instance_double(
      RSpec::Core::Example,
      execution_result: instance_double(RSpec::Core::Example::ExecutionResult, exception: nil).as_null_object,
      full_description: 'the example',
      location_rerun_argument: nil,
      location: nil,
      metadata: {}
    )

    notifications = [[], [failed_example]].map do |failed_examples|
      described_class.from_rspec(
        instance_double(
          RSpec::Core::Notifications::ExamplesNotification,
          instance_variable_get: instance_double(
            RSpec::Core::Reporter,
            examples: [],
            failed_examples: failed_examples,
            pending_examples: []
          )
        )
      )
    end

    expect(notifications.reduce(:+)).to have_attributes(
      failed_examples: [have_attributes(full_description: 'the example')]
    )
  end
end
