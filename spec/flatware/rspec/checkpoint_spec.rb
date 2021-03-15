require 'spec_helper'
require 'flatware/rspec/checkpoint'
require 'rspec/core/notifications'

describe Flatware::RSpec::Checkpoint do
  context 'when summed and some have errors' do
    it 'has errors' do
      failure_notification = instance_double(
        ::RSpec::Core::Example,
        full_description: 'bad news',
        execution_result: instance_double(::RSpec::Core::Example::ExecutionResult, exception: nil).as_null_object,
        location: nil,
        location_rerun_argument: nil,
        metadata: {}
      )

      bad_news = described_class.new(
        dump_summary: Flatware::RSpec::Marshalable::SummaryNotification.from_rspec(
          ::RSpec::Core::Notifications::SummaryNotification.new(0, [], [failure_notification], [], 0, 0)
        )
      )

      good_news = described_class.new(
        dump_summary: Flatware::RSpec::Marshalable::SummaryNotification.from_rspec(
          ::RSpec::Core::Notifications::SummaryNotification.new(0, [], [], [], 0, 0)
        )
      )

      sum = bad_news + good_news
      expect(sum).to be_failures
    end
  end

  it 'accrues deprecations' do
    add_deprecation = lambda do |checkpoint|
      checkpoint.deprecation(instance_double(::RSpec::Core::Notifications::DeprecationNotification))
    end

    checkpoint1 = described_class.new
    checkpoint2 = described_class.new

    2.times { add_deprecation.call(checkpoint1) }
    add_deprecation.call(checkpoint2)

    expect((checkpoint1 + checkpoint2).deprecations.size).to eq(3)
  end
end
