require 'forwardable'
require 'ffi-rzmq'

module Flatware
  require 'flatware/checkpoint_handler'
  require 'flatware/processor_info'
  require 'flatware/checkpoint'
  require 'flatware/cli'
  require 'flatware/cucumber'
  require 'flatware/dispatcher'
  require 'flatware/fireable'
  require 'flatware/formatters'
  require 'flatware/result'
  require 'flatware/scenario_result'
  require 'flatware/sink'
  require 'flatware/step_result'
  require 'flatware/worker'
  require 'flatware/scenario_decorator'

  Error = Class.new StandardError

  Job = Struct.new :id, :args do
    attr_accessor :worker
  end

  extend self
  def socket(type, options={})
    Socket.new(context.socket(type)).tap do |socket|
      sockets.push socket
      if port = options[:connect]
        socket.connect port
      end
      if port = options[:bind]
        socket.bind port
      end
      #FIXME: figure out how to do this without waiting
      sleep 0.05
    end
  end

  def close
    sockets.each &:close
    context.terminate
    @context = nil
  end

  def log(*message)
    if verbose?
      $stderr.print "#{$$} "
      $stderr.puts *message
    end
  end

  attr_writer :verbose
  def verbose?
    !!@verbose
  end

  private
  def context
    @context ||= ZMQ::Context.new
  end

  def sockets
    @sockets ||= []
  end

  Socket = Struct.new :s do
    extend Forwardable
    def_delegators :s, :bind, :connect, :setsockopt
    def send(message)
      result = s.send_string(Marshal.dump(message))
      raise Error, ZMQ::Util.error_string, caller if result == -1
      message
    end

    def close
      s.setsockopt(ZMQ::LINGER, 1)
      s.close
    end

    def recv
      message = ''
      result = s.recv_string(message)
      raise Error, ZMQ::Util.error_string, caller if result == -1
      Marshal.load message
    end
  end
end
