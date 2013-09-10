require 'flatware/socket'

describe Flatware::Socket do
  describe 'recv' do
    let(:s) { double 'ZMQ::Socket', recv_string: -1 }
    subject(:socket) { described_class.new s }
    context 'non blocking read' do
      it 'returns a message if one is ready' do
        def s.recv_string(m, *)
          m.concat Marshal.dump 'message'
          0
        end

        socket.recv(ZMQ::NonBlocking).should eq 'message'
      end

      it 'raises if something besides EAGAIN happened' do
        FFI.stub errno: 666
        expect do
          socket.recv(ZMQ::NonBlocking)
        end.to raise_error Flatware::Error
      end

      it 'returns nil when there is no message' do
        FFI.stub errno: Errno::EAGAIN::Errno
        socket.recv(ZMQ::NonBlocking).should be_nil
      end
    end
  end
end
