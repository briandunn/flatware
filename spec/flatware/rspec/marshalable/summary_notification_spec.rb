require 'spec_helper'
require 'flatware/rspec/marshalable/summary_notification'

describe Flatware::RSpec::Marshalable::SummaryNotification do
  let(:args1) { [1, [], [], [], 0.2, 6] }
  let(:args2) { [2, [], [], [], 0.3, 6] }

  it 'can be added together (duration and load_time handled with #max)' do
    expected_result = {
      duration: 2,
      examples: [],
      failed_examples: [],
      pending_examples: [],
      load_time: 0.3,
      errors_outside_of_examples_count: 12
    }

    summary1 = described_class.new(*args1)
    summary2 = described_class.new(*args2)
    result = summary1 + summary2

    expect(result.to_h).to eq(expected_result)
  end

  it 'plays nice with the rspec formatting stuff' do
    notification = RSpec::Core::Notifications::SummaryNotification.new(*args1)
    summary = described_class.from_rspec(notification)
    expect(summary.fully_formatted).to match(/Finished/)
  end
end
