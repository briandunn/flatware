# frozen_string_literal: true

require 'spec_helper'
require 'flatware/rspec/job_builder'

describe Flatware::RSpec::JobBuilder do
  before do
    allow(RSpec.configuration).to(
      receive(:files_to_run).and_return(files_to_run)
    )
  end

  let(:duration_provider) { double('duration_provider', seconds_per_file: seconds_per_file) }
  let(:seconds_per_file) { [] }
  let(:files_to_run) { [] }

  subject do
    described_class.new([], workers: 2, duration_provider: duration_provider).jobs
  end

  context 'when this run includes persisted examples' do
    let(:seconds_per_file) do
      {
        './fast_1_spec.rb' => 1.0,
        './fast_2_spec.rb' => 1.0,
        './fast_3_spec.rb' => 1.0,
        './slow_spec.rb' => 2.0
      }
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
