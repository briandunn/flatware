# frozen_string_literal: true

require 'spec_helper'
require 'flatware/rspec'

describe Flatware::RSpec::Formatter do
  context 'when example_passed' do
    it "sends a 'passed' progress message to the sink client" do
      client = double 'Client', progress: true
      formatter = described_class.new client
      example = double 'Example'
      formatter.example_passed example

      expect(client).to have_received(:progress).with anything do |message|
        expect(message.progress).to eq :passed
        true
      end
    end
  end
end
