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
    puts "#{$$} closing"
    sockets.each &:close
    context.close
  end

  private
  def context
    return @context if @context
    puts "#{$$} context"
    @context = ZMQ::Context.new
  end

  def sockets
    @sockets ||= []
  end
end
