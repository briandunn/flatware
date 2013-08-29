require 'spec_helper'

describe Flatware::Dispatcher do
  context 'when a dispatcher is started' do
    it 'exits when fired' do
      fork do
        Flatware::Fireable.bind
        socket = Flatware.socket ZMQ::REQ, connect: described_class::PORT
        socket.send 'ready'
        socket.recv
        Flatware::Fireable.kill
        Flatware.close
      end
      pid = fork { described_class.start [:job] }
      exit_statuses = waitall.map(&:last)
      exit_statuses.all?(&:success?).should be
      child_pids.should_not include pid
    end

    it 'dispatches jobs' do
      pid = fork do
        described_class.start [:job1, :job2]
      end
      socket = Flatware.socket ZMQ::REQ, connect: described_class::PORT
      socket.send 'ready'
      socket.recv.should eq :job1
      socket.send 'ready'
      socket.recv.should eq :job2
      socket.send 'ready'
      socket.recv.should eq 'seppuku'
      Flatware.close
      Process.kill 'INT', pid
      waitall
    end
  end
end
