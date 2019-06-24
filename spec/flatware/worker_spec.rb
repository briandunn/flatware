require 'spec_helper'

describe Flatware::Worker do
  context 'when a worker is started' do
    let(:sink_endpoint) { 'ipc://test-sink' }
    let(:runner) { double 'Runner', run: nil }

    it 'exits when dispatch is done' do
      sink = instance_double Flatware::Sink::Server, ready: 'seppuku'
      allow(DRbObject).to receive(:new_with_uri).and_return(sink)

      described_class.new(1, runner, sink_endpoint).listen
    end
  end
end
