require 'rspec/core/formatters/progress_formatter'
module Flatware::Formatters::RSpec
  class Console
    attr_reader :formatter

    def initialize(out, err)
      ::RSpec::configuration.tty = true
      ::RSpec::configuration.color = true
      @formatter = ::RSpec::Core::Formatters::ProgressFormatter.new(out)
      def formatter.dump_commands_to_rerun_failed_examples; end
    end

    def progress(result)
      formatter.send(message_for(result),nil)
    end

    def summarize(checkpoints)
      result = checkpoints.reduce :+
      formatter.dump_summary result.summary
      formatter.dump_failures result
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
