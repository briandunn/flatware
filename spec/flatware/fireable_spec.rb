require 'spec_helper'
describe Flatware::Fireable do

  let! :kill_socket do
    Flatware.socket ZMQ::PUB
  end

  let!(:fireable) { described_class.new }
  let(:port) { 'ipc://test' }
  let!(:rep_socket) { Flatware.socket ZMQ::REP, bind: port }
  let!(:req_socket) { Flatware.socket ZMQ::REQ, connect: port }

  context "in process" do
    it "yields messages that come in on the given socket" do
      req_socket.send :hi!
      monitor = kill_socket.monitor

      kill_socket.bind described_class::PORT
      loop do
        break if monitor.recv == :EVENT_ACCEPTED
      end

      kill_socket.send 'seppuku'

      actual_message = nil
      fireable.until_fired rep_socket do |message|
        actual_message = message
      end
      actual_message.should eq :hi!
    end

    it "exits cleanly when sent the die message" do
      expect(Flatware).to receive(:close).and_call_original

      called = false
      kill_socket.bind described_class::PORT
      monitor = kill_socket.monitor
      loop do
        break if monitor.recv == :EVENT_ACCEPTED
      end
      kill_socket.send 'seppuku'
      fireable.until_fired rep_socket do |message|
        called = true
      end
      called.should_not be
    end
  end
end
