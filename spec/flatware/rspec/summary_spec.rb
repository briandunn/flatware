require 'spec_helper'
require 'flatware/rspec/summary'
describe Flatware::RSpec::Summary do
  it "can be added together" do
    summary_1 = described_class.new 1, 1, 1, 1, 5
    summary_2 = described_class.new 1, 2, 3, 4, 5
    result = summary_1 + summary_2
    expect(result.duration).to eq 2
    expect(result.examples).to eq 3
    expect(result.failed_examples).to eq 4
    expect(result.pending_examples).to eq 5
  end
end
