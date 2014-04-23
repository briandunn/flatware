require 'spec_helper'
require 'flatware/rspec'
describe Flatware::RSpec::Summary do
  it "can be added together" do
    summary_1 = described_class.new 1, 1, 1, 1
    summary_2 = described_class.new 1, 2, 3, 4
    result = summary_1 + summary_2
    result.duration.should eq 2
    result.example_count.should eq 3
    result.failure_count.should eq 4
    result.pending_count.should eq 5
  end
end
