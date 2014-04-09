require 'rspec/core/formatters/progress_formatter'
module Flatware::Formatters::RSpec
  class Console < ::RSpec::Core::Formatters::ProgressFormatter
    def initialize(out, err)
      ::RSpec::configuration.tty = true
      ::RSpec::configuration.color = true
      super(out)
    end

    def summarize(*args)
    end
  end
end
