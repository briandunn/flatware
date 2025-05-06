require 'spec_helper'
require 'flatware/rspec'

describe Flatware::RSpec::Formatter do
  context 'when example_passed' do
    it "sends a 'passed' progress message to the sink client" do
      formatter = described_class.new StringIO.new
      example = double 'Example', full_description: 'example description',
                                  location: 'here',
                                  location_rerun_argument: 'here[1]',
                                  metadata: {},
                                  execution_result: double(
                                    'Execution result',
                                    status: :passed,
                                    exception: nil,
                                    finished_at: Time.now,
                                    run_time: 0.1,
                                    started_at: Time.now - 0.1
                                  )
      notification = double 'Notification', example: example
      client = double 'Client', progress: true
      Flatware::Sink.client = client
      formatter.example_passed notification

      expect(client).to have_received(:progress).with anything do |message|
        expect(message.example.execution_result.status).to eq :passed
        true
      end
    end
  end
end
