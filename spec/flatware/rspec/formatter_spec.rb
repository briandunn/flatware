require 'spec_helper'
require 'flatware/rspec'

describe Flatware::RSpec::Formatter do
  context 'when example_passed' do
    it "sends a 'passed' progress message to the sink client" do
      sink = double Flatware::Sink, progress: nil
      formatter = described_class.new sink
      example = double 'Example'
      formatter.example_passed example

      expect(sink).to have_received(:progress).with anything do |message|
        expect(message.progress).to eq :passed
        true
      end
    end
  end
end
