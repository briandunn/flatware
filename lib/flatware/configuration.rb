# frozen_string_literal: true

module Flatware
  class Configuration
    def initialize
      reset!
    end

    def before_fork(&block)
      if block_given?
        @before_fork = block
      else
        @before_fork
      end
    end

    def after_fork(&block)
      if block_given?
        @after_fork = block
      else
        @after_fork
      end
    end

    def after_forks_complete(&block)
      if block_given?
        @after_forks_complete = block
      else
        @after_forks_complete
      end
    end

    def reset!
      @before_fork = -> {}
      @after_fork = ->(_) {}
      @after_forks_complete = -> {}
    end
  end

  module_function

  def configuration
    @configuration ||= Configuration.new
  end

  def configure(&)
    yield configuration
  end
end
