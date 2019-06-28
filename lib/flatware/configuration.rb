# frozen_string_literal: true

module Flatware
  class Configuration
    def initialize
      @before_fork = -> {}
      @after_fork = ->(_) {}
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
  end

  module_function

  def configuration
    @configuration ||= Configuration.new
  end

  def configure(&_block)
    yield configuration
  end
end
