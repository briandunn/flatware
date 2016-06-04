require 'spec_helper'

describe Flatware::Dispatcher do
  context 'when a dispatcher is started' do
    let(:endpoint) {'ipc://test-dispatch'}
    it 'exits when fired' do
      fork do
        Flatware::Fireable.bind
        socket = Flatware.socket ZMQ::REQ, connect: endpoint
        socket.send 'ready'
        socket.recv
        puts "READY TO KILL"
        Flatware::Fireable.kill
        Flatware.close
        puts "FORK EXIT"
      end
      pid = described_class.spawn [:job], endpoint
      exit_statuses = waitall.map(&:last)
      exit_statuses.all?(&:success?).should be
      child_pids.should_not include pid
    end

    it 'dispatches jobs' do
      pid = described_class.spawn [:job1, :job2], endpoint
      socket = Flatware.socket ZMQ::REQ, connect: endpoint
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
