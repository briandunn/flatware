require 'spec_helper'

describe Flatware::Dispatcher do
  context 'when a dispatcher is started' do
    after { Flatware.close }
    it 'exits when fired' do
      pid = fork { described_class.start [:job] }
      Flatware::Fireable.bind
      wait_until { child_pids.include? pid }
      Flatware::Fireable.kill
      Process.wait pid
      exit_statuses = Process.waitall.map(&:last)
      exit_statuses.all?(&:success?).should be
      child_pids.should_not include pid
    end

    it 'dispatches jobs' do
      pid = fork { described_class.start [:job1, :job2] }
      socket = Flatware.socket ZMQ::REQ, connect: described_class::PORT
      socket.send 'ready'
      socket.recv.should eq :job1
      socket.send 'ready'
      socket.recv.should eq :job2
      socket.send 'ready'
      socket.recv.should eq 'seppuku'
      Process.kill 'INT', pid
      Process.wait pid
    end
  end
end
