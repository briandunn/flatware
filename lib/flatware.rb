require 'logger'

module Flatware
  require 'flatware/processor_info'
  require 'flatware/job'
  require 'flatware/cli'
  require 'flatware/sink'
  require 'flatware/worker'
  require 'flatware/broadcaster'

  extend self

  def logger
    @logger ||= Logger.new($stderr)
  end

  def logger=(logger)
    @logger = logger
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
end
