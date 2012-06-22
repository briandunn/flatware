require 'yaml'
require 'zmq'
module Flatware
  autoload :Dispatcher, 'flatware/dispatcher'
  autoload :Cucumber, 'flatware/cucumber'
  autoload :Fireable, 'flatware/fireable'
  autoload :Worker, 'flatware/worker'
  autoload :Sink, 'flatware/sink'
  autoload :CLI, 'flatware/cli'

  extend self
  def socket(*args)
   context.socket(*args).tap do |socket|
     sockets.push socket
   end
  end

  def close
    sockets.each &:close
    context.close
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
    return @context if @context
    @context = ZMQ::Context.new
  end

  def sockets
    @sockets ||= []
  end
end
