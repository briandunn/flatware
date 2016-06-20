require 'flatware/poller'

module Flatware
  class Fireable
    PORT = 'ipc://die'

    def self.bind
      @kill = Flatware.socket ZMQ::PUB
      monitor = @kill.monitor
      @kill.bind PORT
      while message = monitor.recv
        if message == :EVENT_ACCEPTED
          break
        end
      end
    end

    def self.kill
      @kill.send 'seppuku'
    end

    def initialize
      @die = Flatware.socket ZMQ::SUB
      Thread.current[:die] = @die
      @die.connect PORT
      @die.setsockopt ZMQ::SUBSCRIBE, ''
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
