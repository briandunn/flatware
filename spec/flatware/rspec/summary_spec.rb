require 'spec_helper'
require 'flatware/rspec'
describe Flatware::RSpec::Summary do
  it "can be added together" do
    summary_1 = described_class.new 1, 1, 1, 1
    summary_2 = described_class.new 1, 2, 3, 4
    result = summary_1 + summary_2
    expect(result.duration).to eq 2
    expect(result.example_count).to eq 3
    expect(result.failure_count).to eq 4
    expect(result.pending_count).to eq 5
  end
end
