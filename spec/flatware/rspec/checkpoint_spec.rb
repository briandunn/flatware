require 'spec_helper'
require 'flatware/rspec/checkpoint'
require 'rspec/core/notifications'

describe Flatware::RSpec::Checkpoint do
  context 'when summed and some have errors' do
    it 'has errors' do
      failure_notification = instance_double(
        ::RSpec::Core::Example,
        full_description: 'bad news',
        execution_result: nil,
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
end
