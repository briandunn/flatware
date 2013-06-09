module Flatware
  class Fireable
    PORT = 'ipc://die'

    def self.bind
      @kill = Flatware.socket(ZMQ::PUB, bind: PORT)
    end

    def self.kill
      @kill.send 'seppuku'
    end

    def initialize
      @die = Flatware.socket(ZMQ::SUB, connect: PORT).tap do |die|
        die.setsockopt ZMQ::SUBSCRIBE, ''
      end
    end

    attr_reader :die

    def until_fired(socket, &block)
      poller = Poller.new socket, die
      poller.each do |message|
        break if message == 'seppuku'
        block.call message
      end
    ensure
      Flatware.close
    end
  end

  class Poller
    attr_reader :sockets, :zmq_poller
    def initialize(*sockets)
      @sockets    = sockets
      @zmq_poller = ZMQ::Poller.new
      register_sockets
    end

    def each(&block)
      while zmq_poller.poll > 0
        zmq_poller.readables.each do |s|
          block.call Socket.new(s).recv
        end
      end
    end

    private

    def register_sockets
      sockets.each { |socket| zmq_poller.register_readable socket.s }
    end
  end
end
