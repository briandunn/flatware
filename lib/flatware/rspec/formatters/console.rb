require 'rspec/core'

module Flatware
  module RSpec
    module Formatters
      class Console
        attr_reader :progress_formatter, :profile_formatter

        def initialize(out, _err)
          ::RSpec.configuration.tty = true
          ::RSpec.configuration.color = true
          @progress_formatter = ::RSpec::Core::Formatters::ProgressFormatter.new(out)
          @profile_formatter = ::RSpec::Core::Formatters::ProfileFormatter.new(out)
        end

        def progress(result)
          progress_formatter.send(message_for(result), nil)
        end

        def summarize(checkpoints)
          return if checkpoints.empty?

          result = checkpoints.reduce :+

          profile_formatter.dump_profile result.profile if result.profile
          progress_formatter.dump_failures result
          progress_formatter.dump_summary result.summary
        end

        def summarize_remaining(remaining)
          progress_formatter.output.puts(colorizer.wrap(<<~MESSAGE, :detail))

            The following specs weren't run:

            #{spec_list(remaining)}

          MESSAGE
        end

        private

        def spec_list(remaining)
          remaining
            .flat_map(&:id).sort.each_with_index
            .map do |example, index|
            format(
              '%<index>4d) %<example>s',
              index: index.next,
              example: example
            )
          end.join("\n")
        end

        def colorizer
          ::RSpec::Core::Formatters::ConsoleCodes
        end

        def message_for(result)
          {
            passed: :example_passed,
            failed: :example_failed,
            pending: :example_pending
          }.fetch result.progress
        end
      end
    end
  end
end
