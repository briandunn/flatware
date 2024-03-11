# frozen_string_literal: true

require 'logger'

module Flatware
  require 'flatware/job'
  require 'flatware/cli'
  require 'flatware/sink'
  require 'flatware/worker'
  require 'flatware/worker_manager'
  require 'flatware/broadcaster'

  module_function

  def logger
    @logger ||= Logger.new($stderr, level: :fatal)
  end

  def logger=(logger)
    @logger = logger
  end

  def log(*message)
    case message.first
    when Exception
      logger.error message.first
    else
      logger.info(([$PROGRAM_NAME] + message).join(' '))
    end
    message
  end

  def verbose=(bool)
    logger.level = bool ? :debug : :fatal
  end

  def verbose?
    logger.level < Logger::SEV_LABEL.index('FATAL')
  end
end
