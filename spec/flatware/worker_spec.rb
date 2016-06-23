require 'spec_helper'

describe Flatware::Worker do
  context 'when a worker is started' do
    let(:dispatch_endpoint) { 'ipc://test-dispatch' }
    let(:sink_endpoint) { 'ipc://test-sink' }
    let(:runner) { double 'Runner', run: nil }

    it 'exits when dispatch is done' do
      socket = double 'Socket', recv: 'seppuku', send: nil

      allow(Flatware).to receive(:socket) { socket }
      described_class.new(1, runner, dispatch_endpoint, sink_endpoint).listen
    end
  end
end
