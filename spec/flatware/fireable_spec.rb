require 'spec_helper'
describe Flatware::Fireable do
  let(:controll_socket) { double 'controll socket', recv: 'seppuku', setsockopt: nil }
  subject(:fireable) { described_class.new }
  let(:poller) { double 'poller' }
  before do
    Flatware::Poller.stub new: poller
    Flatware.should_receive(:socket).and_return controll_socket
  end
  let(:client_socket) { double 'client socket', recv: 'client message' }

  it "yields messages that come in on the given socket" do
    poller.stub(:each).and_yield(client_socket)
    fireable.until_fired client_socket do |message|
      message.should eq 'client message'
    end
  end

  it "exits cleanly when sent the die message" do
    poller.stub(:each).and_yield(controll_socket)
    called = nil

    fireable.until_fired client_socket do |message|
      called = true
    end
    called.should_not be
  end

  it 'exits cleanly when employment is checked' do
    poller.stub(:each).and_yield(client_socket)
    Flatware.should_receive :close
    fireable.until_fired client_socket do
      fireable.ensure_employment!
    end
  end
end
