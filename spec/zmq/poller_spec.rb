require 'spec_helper'

describe 'Our bad situation' do
  it 'Pub sub takes too long to init' do
    pub_socket = Flatware.socket(ZMQ::PUB, bind: 'ipc://die')

    sub_socket = Flatware.socket(ZMQ::SUB, connect: 'ipc://die').tap do |die|
      die.setsockopt ZMQ::SUBSCRIBE, ''
    end

    monitor = pub_socket.monitor
    true until monitor.recv == :EVENT_ACCEPTED
    pub_socket.send('something')
    message = sub_socket.recv
    expect(message).to eq 'something'
  end
end
