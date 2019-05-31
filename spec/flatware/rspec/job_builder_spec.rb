# frozen_string_literal: true

require 'spec_helper'
require 'flatware/rspec/job_builder'

describe Flatware::RSpec::JobBuilder do
  before do
    allow(::RSpec::Core::ExampleStatusPersister).to(
      receive(:load_from).and_return(persisted_examples)
    )

    allow(::RSpec.configuration).to(
      receive(:files_to_run).and_return(files_to_run)
    )
  end

  let(:persisted_examples) { [] }
  let(:files_to_run) { [] }

  context 'when persisted examples include files in this run' do
    let(:persisted_examples) do
      [
        { example_id: './fast_1_spec.rb[1]', run_time: '1 second', status: 'passed' },
        { example_id: './fast_2_spec.rb[1]', run_time: '1 second', status: 'passed' },
        { example_id: './slow_spec.rb[1]', run_time: '2 seconds', status: 'passed' }
      ]
    end

    let(:files_to_run) { %w[fast_1_spec.rb fast_2_spec.rb slow_spec.rb] }

    it 'groups them into equal time blocks' do
      expect(described_class.new([], workers: 2).jobs).to match_array(
        [
          have_attributes(id: match_array(%w[./fast_1_spec.rb ./fast_2_spec.rb])),
          have_attributes(id: match_array(%w[./slow_spec.rb]))
        ]
      )
    end
  end

  describe '#jobs' do
    it 'balances jobs by expected time' do
    end

    it 'assigns untimed specs round robin' do
    end
  end
end
