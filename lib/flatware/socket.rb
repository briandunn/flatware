require 'ffi-rzmq'

module Flatware
  Error = Class.new StandardError

  Job = Struct.new :id, :args do
    attr_accessor :worker
  end

  extend self

  def socket(*args)
    context.socket(*args)
  end

  def close
    context.close
    @context = nil
  end

  def log(*message)
    if verbose?
      $stderr.print "#$0 "
      $stderr.puts *message
      $stderr.flush
    end
    message
  end

  attr_writer :verbose
  def verbose?
    !!@verbose
  end

  def context
    @context ||= Context.new
  end

  def raise_errno
    raise error_for_errno
  end

  def error_for_errno
    Errno.constants.map do |c|
      {Errno.const_get(c).const_get(:Errno) => Errno.const_get(c) }
    end.reduce(:merge)[FFI.errno] || Error
  end

  class Context
    attr_reader :sockets, :c

    def initialize
      @c = ZMQ::Context.new
      @sockets = []
    end

    def socket(type, options={})
      Socket.new(c.socket(type)).tap do |socket|
        sockets.push socket
        if port = options[:connect]
          socket.connect port
          sleep 0.05
        end
        if port = options[:bind]
          socket.bind port
        end
      end
    end

    def close
      sockets.each &:close
      raise_errno unless c.terminate == 0
      Flatware.log "terminated context"
    end
  end

  class Socket
    attr_reader :s, :endpoint
    def initialize(socket)
      @s = socket
    end

    def setsockopt(*args)
      s.setsockopt(*args)
    end

    def send(message, flag=0)
      result = s.send_string(Marshal.dump(message), flag)
      return message if non_blocking?(result, flag)
      Flatware.log "#@type #@endpoint send #{message}"
      message
    end

    def connect(endpoint)
      @type = 'connected'
      @endpoint = endpoint
      raise_errno unless s.connect(endpoint) == 0
      Flatware.log "connect #@endpoint"
    end

    def bind(endpoint)
      @type = 'bound'
      @endpoint = endpoint
      raise_errno unless s.bind(endpoint) == 0
      Flatware.log "bind #@endpoint"
    end

    def close
      setsockopt ZMQ::LINGER, 0
      raise_errno unless s.close == 0
      Flatware.log "close #@type #@endpoint"
    end

    def recv(flag=0)
      message = ''
      result = s.recv_string(message, flag)
      return if non_blocking?(result, flag)
      message = Marshal.load message
      Flatware.log "#@type #@endpoint recv #{message}"
      message
    end

    private

    def raise_errno
      Flatware.raise_errno
    end

    def non_blocking?(result, flag)
      Flatware.error_for_errno == Errno::EAGAIN && flag == ZMQ::NonBlocking or raise_errno if result == -1
    end
  end
end
