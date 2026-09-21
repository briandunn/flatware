# frozen_string_literal: true

require 'spec_helper'
require 'flatware/rspec/example_job_builder'

describe Flatware::RSpec::ExampleJobBuilder do
  before do
    allow(RSpec::Core::ExampleStatusPersister).to(
      receive(:load_from).and_return(persisted_examples)
    )

    allow_any_instance_of(RSpec::Core::World).to(
      receive(:ordered_example_groups).and_return(ordered_example_groups)
    )
  end

  let(:persisted_examples) { [] }
  let(:examples_to_run) { [] }
  let(:ordered_example_groups) do
    examples_to_run
      .group_by { |example_id| example_id.split('[').first }
      .map do |_file_name, example_ids|
        double(descendants: [double(filtered_examples: example_ids.map { |id| double(id: id) })])
      end
  end

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

    let(:examples_to_run) { %w(./fast_1_spec.rb[1] ./fast_2_spec.rb[1] ./slow_spec.rb[1]) }

    it 'groups them into equal time blocks' do
      expect(subject).to match_array(
        [
          have_attributes(
            id: match_array(%w[./fast_1_spec.rb[1] ./fast_2_spec.rb[1]])
          ),
          have_attributes(id: match_array(%w[./slow_spec.rb[1]]))
        ]
      )
    end

    context 'and this run includes examples that are not persisted' do
      let(:examples_to_run) do
        %w[
          ./fast_1_spec.rb[1]
          ./fast_2_spec.rb[1]
          ./slow_spec.rb[1]
          ./new_1_spec.rb[1]
          ./new_2_spec.rb[1]
          ./new_3_spec.rb[1]
        ]
      end

      it 'assigns the remaining files round-robin' do
        expect(subject).to match_array(
          [
            have_attributes(id: include('./new_1_spec.rb[1]', './new_3_spec.rb[1]')),
            have_attributes(id: include('./new_2_spec.rb[1]'))
          ]
        )
      end
    end

    context 'and an example from one file takes longer than all other examples' do
      let(:persisted_examples) do
        [
          { example_id: './spec_1.rb[1]', run_time: '10 seconds' },
          { example_id: './spec_1.rb[2]', run_time: '1 second' },
          { example_id: './spec_1.rb[3]', run_time: '1 second' },
          { example_id: './spec_2.rb[1]', run_time: '1 second' },
          { example_id: './spec_2.rb[2]', run_time: '1 second' },
          { example_id: './spec_2.rb[3]', run_time: '1 second' }
        ].map { |example| example.merge status: 'passed' }
      end

      let(:examples_to_run) do
        %w(./spec_1.rb[1] ./spec_1.rb[2] ./spec_1.rb[3] ./spec_2.rb[1] ./spec_2.rb[2] ./spec_2.rb[3])
      end

      it 'assigns that example as sole in one job' do
        expect(subject).to match_array(
          [
            have_attributes(id: ['./spec_1.rb[1]']),
            have_attributes(id: match_array(%w[./spec_1.rb[2] ./spec_1.rb[3] ./spec_2.rb[1] ./spec_2.rb[2]
                                               ./spec_2.rb[3]]))
          ]
        )
      end
    end
  end
end
