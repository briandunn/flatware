require 'ffi-rzmq'
require 'securerandom'
require 'logger'

module Flatware
  Error = Class.new StandardError

  Job = Struct.new :id, :args do
    attr_accessor :worker
    attr_writer :failed

    def failed?
      !!@failed
    end
  end

  extend self

  def logger
    @logger ||= Logger.new($stderr)
  end

  def logger=(logger)
    @logger = logger
  end

  def socket(*args)
    context.socket(*args)
  end

  def close(force: false)
    @ignore_errors = true if force
    context.close(force: force)
    @context = nil
  end

  def close!
    close force: true
  end

  def socket_error(name=nil)
    raise(Error, [$0,name,ZMQ::Util.error_string].compact.join(' - '), caller) unless @ignore_errors
  end

  def log(*message)
    if Exception === message.first
      logger.error message.first
    elsif verbose?
      logger.info ([$0] + message).join(' ')
    end
    message
  end

  attr_writer :verbose
  def verbose?
    !!@verbose
  end

  def context
    @context ||= begin
                   @ignore_errors = nil
                   Context.new
                 end
  end

  class Context
    attr_reader :sockets, :c

    def initialize
      @c = ZMQ::Context.new
      @sockets = []
    end

    def socket(zmq_type, options={})
      Socket.new(c.socket(zmq_type)).tap do |socket|
        sockets.push socket
        if port = options[:connect]
          socket.connect port
        end
        if port = options[:bind]
          socket.bind port
        end
      end
    end

    def close(force: false)
      sockets.each do |socket|
        socket.setsockopt ZMQ::LINGER, 0
      end if force
      sockets.each(&:close)
      Flatware::socket_error unless LibZMQ.zmq_term(c.context) == 0
      Flatware.log "terminated context"
    end
  end

  class Socket
    attr_reader :socket

    def initialize(socket)
      @socket = socket
    end

    def setsockopt(*args)
      socket.setsockopt(*args)
    end

    def name
      socket.name
    end

    def send(message)
      result = socket.send_string(Marshal.dump(message))
      error if result == -1
      Flatware.log "#@type #@port send #{message}"
      message
    end

    def connect(port)
      @type = 'connected'
      @port = port
      error unless socket.connect(port) == 0
      Flatware.log "connect #@port"
    end

    def monitor
      name = "inproc://monitor#{SecureRandom.hex(10)}"
      LibZMQ.zmq_socket_monitor(socket.socket, name, ZMQ::EVENT_ALL)
      Monitor.new(name)
    end

    class Monitor
      def initialize(port)
        @socket = Flatware.socket ZMQ::PAIR
        @socket.connect port
      end

      def recv
        bytes = @socket.recv marshal: false
        data = LibZMQ::EventData.new FFI::MemoryPointer.from_string bytes
        event[data.event]
      end

      private

      def event
        ZMQ.constants.select do |c|
          c.to_s =~ /^EVENT/
        end.map do |s|
          {s => ZMQ.const_get(s)}
        end.reduce(:merge).invert
      end
    end

    def bind(port)
      @type = 'bound'
      @port = port
      error unless socket.bind(port) == 0
      Flatware.log "bind #@port"
    end

    def close
      error unless socket.close == 0
      Flatware.log "close #@type #@port"
    end

    def error
      Flatware::socket_error name
    end

    def recv(block: true, marshal: true)
      message = ''
      if block
       result = socket.recv_string(message)
       error if result == -1
      else
        socket.recv_string(message, ZMQ::NOBLOCK)
      end
      if message != '' and marshal
        message = Marshal.load(message)
      end
      Flatware.log "#@type #@port recv #{message}"
      message
    end
  end
end
