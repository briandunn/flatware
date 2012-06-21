module Flatware
  class Fireable
    def initialize
      @die = Flatware.socket(ZMQ::SUB).tap do |die|
        die.connect 'ipc://die'
        die.setsockopt ZMQ::SUBSCRIBE, ''
      end
    end

    attr_reader :die

    def until_fired(sockets=[], &block)
      quit = false
      while !quit && (ready = ZMQ.select(Array(sockets) + [die]))
        messages = ready.flatten.compact.map(&:recv)
        return if messages.include? 'seppuku'
        messages.each &block
      end
    ensure
      Flatware.close
    end
  end
end
