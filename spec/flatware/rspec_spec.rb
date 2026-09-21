# frozen_string_literal: true

require 'spec_helper'
require 'aruba/rspec'

describe Flatware::RSpec do
  describe '.run', type: :aruba do
    # Workers pull jobs from a shared queue, so one worker process can run
    # several jobs, while `--require spec_helper` is only evaluated once per process.
    it 'keeps the spec_helper configuration for later jobs in the same process' do
      write_file '.rspec', '--require spec_helper'
      write_file 'spec/spec_helper.rb', <<~RB
        module ConfiguredHelper
          def configured_helper = :configured
        end

        RSpec.configure do |config|
          config.include ConfiguredHelper
        end
      RB

      %w[first second].each do |name|
        write_file "spec/#{name}_spec.rb", <<~RB
          describe '#{name}' do
            it { expect(configured_helper).to eq :configured }
          end
        RB
      end

      write_file 'run_two_jobs.rb', <<~RB
        $LOAD_PATH.unshift '#{Pathname(__dir__).join('../../lib').expand_path}'
        require 'flatware/rspec'

        class PrintingSink
          def progress(*); end
          def message(*); end

          def checkpoint(checkpoint)
            puts checkpoint.summary.totals_line
            puts checkpoint.fully_formatted_failed_examples if checkpoint.failures?
          end
        end

        Flatware::Sink.client = PrintingSink.new

        Flatware::RSpec.run('spec/first_spec.rb', [])
        Flatware::RSpec.run('spec/second_spec.rb', [])
      RB

      run_command_and_stop 'ruby run_two_jobs.rb'

      expect(last_command_started).to have_output(/1 example, 0 failures\n1 example, 0 failures/)
    end
  end
end
