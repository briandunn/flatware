require 'spec_helper'
require 'flatware/rspec'

describe Flatware::RSpec::Formatter do
  context "when example_passed" do
    it "sends a 'passed' progress message to the sink client" do
      formatter = described_class.new
      example = double 'Example'
      client = double 'Client'
      client.should_receive(:progress).with anything do |message|
        message.progress.should eq :passed
        true
      end

      Flatware::Sink::client = client
      formatter.example_passed example
    end
  end
end
