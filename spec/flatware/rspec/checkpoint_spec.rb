require 'spec_helper'
require 'flatware/rspec/checkpoint'
require 'rspec/core/notifications'

describe Flatware::RSpec::Checkpoint do
  context 'when summed and some have errors' do
    it 'has errors' do
      failure_notification = instance_double(
        ::RSpec::Core::Notifications::FailedExampleNotification,
        fully_formatted: 'bad news'
      )
      bad_news = described_class.new 1, instance_double(
        ::RSpec::Core::Notifications::ExamplesNotification,
        failure_notifications: [failure_notification, failure_notification]
      )
      good_news = described_class.new 1, instance_double(
        ::RSpec::Core::Notifications::ExamplesNotification,
        failure_notifications: []
      )

      sum = bad_news + good_news
      expect(sum.failures_notification.failure_notifications.size).to eq 2
      expect(sum.fully_formatted_failed_examples).to include 'bad news'
    end
  end
end
