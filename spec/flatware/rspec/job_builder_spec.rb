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

  subject do
    described_class.new([], workers: 2).jobs
  end

  context 'when this run includes persisted examples' do
    let(:persisted_examples) do
      [
        { example_id: './fast_1_spec.rb[1]', run_time: '1 second' },
        { example_id: './fast_2_spec.rb[1]', run_time: '1 second' },
        { example_id: './fast_3_spec.rb[1]', run_time: '1 second' },
        { example_id: './slow_spec.rb[1]', run_time: '2 seconds' }
      ].map { |example| example.merge status: 'passed' }
    end

    let(:files_to_run) { %w[fast_1_spec.rb fast_2_spec.rb slow_spec.rb] }

    it 'groups them into equal time blocks' do
      expect(subject).to match_array(
        [
          have_attributes(
            id: match_array(%w[./fast_1_spec.rb ./fast_2_spec.rb])
          ),
          have_attributes(id: match_array(%w[./slow_spec.rb]))
        ]
      )
    end

    context 'and this run includes examples that are not persisted' do
      let(:files_to_run) do
        %w[
          fast_1_spec.rb
          fast_2_spec.rb
          slow_spec.rb
          new_1_spec.rb
          new_2_spec.rb
          new_3_spec.rb
        ]
      end

      it 'assigns the remaining files round-robin' do
        expect(subject).to match_array(
          [
            have_attributes(id: include('./new_1_spec.rb', './new_3_spec.rb')),
            have_attributes(id: include('./new_2_spec.rb'))
          ]
        )
      end
    end
  end
end
