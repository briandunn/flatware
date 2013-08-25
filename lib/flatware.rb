require 'ffi-rzmq'

module Flatware
  require 'flatware/checkpoint'
  require 'flatware/checkpoint_handler'
  require 'flatware/cli'
  require 'flatware/cucumber'
  require 'flatware/dispatcher'
  require 'flatware/formatters'
  require 'flatware/fireable'
  require 'flatware/poller'
  require 'flatware/result'
  require 'flatware/scenario_decorator'
  require 'flatware/scenario_result'
  require 'flatware/sink'
  require 'flatware/step_result'
  require 'flatware/worker'

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
    @contexts[$$] = nil
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
    (@contexts ||= {})[$$] ||= Context.new
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
          Flatware.log "connect #{port}"
          socket.connect port
          sleep 0.05
        end
        if port = options[:bind]
          Flatware.log "bind #{port}"
          socket.bind port
        end
      end
    end

    def close
      sockets.each &:close
      c.terminate
      Flatware.log "terminated context"
    end
  end

  class Socket
    attr_reader :s
    def initialize(socket)
      @s = socket
    end

    def setsockopt(*args)
      s.setsockopt(*args)
    end

    def send(message)
      Flatware.log "#@type #@port send #{message.first}"
      result = s.send_string(Marshal.dump(message))
      raise Error, ZMQ::Util.error_string, caller if result == -1
      message
    end

    def connect(port)
      @type = 'connected'
      @port = port
      s.connect(port)
    end

    def bind(port)
      @type = 'bound'
      @port = port
      s.bind(port)
    end

    def close
      setsockopt ZMQ::LINGER, 1
      Flatware.log "close #@type #@port"
      s.close
    end

    def recv
      message = ''
      result = s.recv_string(message)
      raise Error, ZMQ::Util.error_string, caller if result == -1
      message = Marshal.load message
      Flatware.log "#@type #@port recv #{message.first}"
      message
    end
  end
end
