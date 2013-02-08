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
    attr_reader :sockets
    def initialize(*sockets)
      @sockets = sockets
    end

    def each(&block)
      poller = ZMQ::Poller.new
      for socket in sockets
        poller.register_readable socket.s
      end
      while poller.poll > 0
        poller.readables.each do |s|
          block.call Socket.new(s).recv
        end
      end
    end
  end
end
