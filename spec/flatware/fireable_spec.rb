require 'spec_helper'
describe Flatware::Fireable do

  let! :kill_socket do
    Flatware.socket ZMQ::PUB, bind: described_class::PORT
  end

  let(:fireable) { described_class.new }
  let(:port) { 'ipc://test' }
  let!(:rep_socket) { Flatware.socket ZMQ::REP, bind: port }
  let!(:req_socket) { Flatware.socket ZMQ::REQ, connect: port }

  context "in process" do
    before { fireable }
    it "yields messages that come in on the given socket" do
      req_socket.send :hi!
      kill_socket.send 'seppuku'

      actual_message = nil
      fireable.until_fired rep_socket do |message|
        actual_message = message
      end
      actual_message.should eq :hi!
    end

    it "exits cleanly when sent the die message" do
      Flatware.should_receive :close
      called = false
      kill_socket.send 'seppuku'
      fireable.until_fired rep_socket do |message|
        called = true
      end
      called.should_not be
    end
  end

  it 'exits cleanly when employment is checked' do
    client_socket = double 'client socket', recv: 'message'
    controll_socket = double 'controll socket', recv: 'seppuku', setsockopt: nil
    poller = double 'poller'
    poller.stub(:each).and_yield(client_socket)
    Flatware.should_receive :close
    Flatware::Poller.stub new: poller
    Flatware.should_receive(:socket).and_return controll_socket
    fireable.until_fired client_socket do
      fireable.ensure_employment!
    end
  end
end
