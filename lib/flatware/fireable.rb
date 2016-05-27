require 'flatware/poller'

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
      poller.each do |s|
        message = s.recv
        break if message == 'seppuku'
        block.call message
      end
    rescue => e
      Flatware.log e
    ensure
      Flatware.close
    end
  end
end
