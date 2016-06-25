module Flatware::Formatters::RSpec
  class Console
    attr_reader :formatter

    def initialize(out, err)
      ::RSpec::configuration.tty = true
      ::RSpec::configuration.color = true
      @formatter = ::RSpec::Core::Formatters::ProgressFormatter.new(out)
    end

    def progress(result)
      formatter.send(message_for(result),nil)
    end

    def summarize(checkpoints)
      result = checkpoints.reduce :+
      if result
        formatter.dump_failures result
        formatter.dump_summary result.summary
      end
    end

    private

    def message_for(result)
      {
        passed:  :example_passed,
        failed:  :example_failed,
        pending: :example_pending
      }.fetch result.progress
    end
  end
end
