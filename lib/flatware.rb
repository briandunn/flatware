require 'zmq'

module Flatware
  autoload :CLI, 'flatware/cli'
  autoload :Cucumber, 'flatware/cucumber'
  autoload :Dispatcher, 'flatware/dispatcher'
  autoload :Fireable, 'flatware/fireable'
  autoload :ProcessorInfo, 'flatware/processor_info'
  autoload :Result, 'flatware/result'
  autoload :ScenarioResult, 'flatware/scenario_result'
  autoload :Sink, 'flatware/sink'
  autoload :StepResult, 'flatware/step_result'
  autoload :Summary, 'flatware/summary'
  autoload :Worker, 'flatware/worker'

  Job = Struct.new :id, :args

  extend self
  def socket(*args)
    context.socket(*args).tap do |socket|
      sockets.push socket
    end
  end

  def close
    sockets.each &:close
    context.close
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
end
