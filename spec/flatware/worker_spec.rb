require 'spec_helper'

describe Flatware::Worker do
  context 'when a worker is started' do
    let(:dispatch_endpoint) { 'ipc://test-dispatch' }
    let(:sink_endpoint) { 'ipc://test-sink' }
    after { Flatware.close }

    let(:worker) { described_class.new 1, dispatch_endpoint, sink_endpoint }

    it 'exits when dispatch is done' do
      pid = fork { worker.listen }
      task = Flatware.socket ZMQ::REP, bind: dispatch_endpoint
      task.recv
      task.send 'seppuku'

      waitall
      child_pids.should_not include pid
    end

    it 'exits when fired' do
      fork do
        Flatware::Fireable.bind
        task = Flatware.socket ZMQ::REP, bind: dispatch_endpoint
        task.recv.should eq 'ready'
        Flatware::Fireable.kill
      end
      wait fork { worker.listen }
    end
  end
end
