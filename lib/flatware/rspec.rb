# frozen_string_literal: true

require 'rspec/core'
require 'rspec/expectations'
require 'flatware/rspec/cli'

module Flatware
  module RSpec
    require 'flatware/rspec/formatter'
    require 'flatware/rspec/job_builder'

    module_function

    def runner
      ::RSpec::Core::Runner.tap do |runner|
        def runner.trap_interrupt() end
      end
    end

    def output_stream
      StringIO.new.tap do |output|
        output.define_singleton_method(:tty?) do
          $stdout.tty?
        end
      end
    end

    def run(job, _options = [])
      ::RSpec.configuration.deprecation_stream = StringIO.new
      ::RSpec.configuration.output_stream = output_stream
      ::RSpec.configuration.add_formatter(Flatware::RSpec::Formatter)

      runner.run(Array(job), $stderr, $stdout)
      ::RSpec.reset # prevents duplicate runs
    end
  end
end
