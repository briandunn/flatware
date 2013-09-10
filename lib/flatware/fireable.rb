require 'flatware/socket'
require 'flatware/poller'

module Flatware
  Fired = Class.new(Error)
  class Fireable
    PORT = 'tcp://127.0.0.1:7892'

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

    def fired?
      @fired ||= die.recv(ZMQ::NonBlocking) == 'seppuku'
    end

    def ensure_employment!
      raise Fired if fired?
    end

    attr_reader :die

    def until_fired(socket, &block)
      poller = Poller.new socket, die
      poller.each do |s|
        message = s.recv
        break if message == 'seppuku' or fired?
        block.call message
      end
    rescue Fired => e
      # quietly bow out. Being asked to quit is a clean exit.
    ensure
      Flatware.close
    end
  end
end
