require 'spec_helper'
require 'flatware/rspec/marshalable/summary_notification'

describe Flatware::RSpec::Marshalable::SummaryNotification do
  def args
    [1, [], [], []] + (5..described_class.members.size).to_a
  end

  it 'can be added together' do
    summary1 = described_class.new(*args)
    summary2 = described_class.new(*args)
    result = summary1 + summary2
    expect(result.to_a).to eq(args.map { |x| x * 2 })
  end

  it 'plays nice with the rspec formatting stuff' do
    notification = ::RSpec::Core::Notifications::SummaryNotification.new(*args)
    summary = described_class.from_notification(notification)
    expect(summary.fully_formatted).to match(/Finished/)
  end
end
