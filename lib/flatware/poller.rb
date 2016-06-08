module Flatware
  class Poller
    attr_reader :sockets, :zmq_poller
    def initialize(*sockets)
      @sockets    = sockets
      @zmq_poller = ZMQ::Poller.new
      register_sockets
    end

    def each(&block)
      while (result = zmq_poller.poll) != 0
        raise Error, ZMQ::Util.error_string, caller if result == -1
        for socket in zmq_poller.readables.map &find_wrapped_socket
          yield socket
        end
      end
    end

    private

    def find_wrapped_socket
      ->(s) do
        sockets.find do |socket|
          socket.socket == s
        end
      end
    end

    def register_sockets
      sockets.each do |socket|
        zmq_poller.register_readable socket.socket
      end
    end
  end
end
