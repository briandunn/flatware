require 'rspec/core'

module Flatware
  module RSpec
    module Formatters
      class Console
        attr_reader :progress_formatter, :out, :deprecation_stream

        def initialize(out, deprecation_stream: StringIO.new)
          @out = out
          @deprecation_stream = deprecation_stream
          ::RSpec.configuration.backtrace_exclusion_patterns += [%r{/lib/flatware/worker}, %r{/lib/flatware/rspec}]
          @progress_formatter = ::RSpec::Core::Formatters::ProgressFormatter.new(out)
        end

        def progress(result)
          progress_formatter.public_send(message_for(result), nil)
        end

        def message(message)
          out.puts(message.message)
        end

        def summarize(checkpoints)
          return if checkpoints.empty?

          result = checkpoints.reduce :+

          progress_formatter.dump_pending(result) if result.pending_examples.any?
          progress_formatter.dump_failures(result)
          dump_deprecations(result.deprecations)
          dump_profile(result.profile) if result.profile
          progress_formatter.dump_summary(result.summary)
        end

        def summarize_remaining(remaining)
          puts colorizer.wrap(<<~MESSAGE, :detail)

            The following specs weren't run:

            #{spec_list(remaining)}

          MESSAGE
        end

        private

        def puts(message)
          progress_formatter.output.puts(message)
        end

        def dump_deprecations(deprecations)
          formatter = ::RSpec::Core::Formatters::DeprecationFormatter.new(
            deprecation_stream,
            out
          )

          deprecations.each(&formatter.method(:deprecation))
          formatter.deprecation_summary(nil)
        end

        def dump_profile(profile)
          ::RSpec::Core::Formatters::ProfileFormatter.new(out).dump_profile(profile)
        end

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
