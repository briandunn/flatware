# frozen_string_literal: true

require 'spec_helper'
require 'flatware/rspec/duration_providers/example_statuses_provider'

describe Flatware::RSpec::DurationProviders::ExampleStatusesProvider do
  before do
    allow(RSpec::Core::ExampleStatusPersister).to(
      receive(:load_from).and_return(persisted_examples)
    )
  end

  let(:persisted_examples) do
    [
      { example_id: './fast_1_spec.rb[1]', run_time: '1 second' },
      { example_id: './fast_2_spec.rb[1]', run_time: '1 second' },
      { example_id: './fast_3_spec.rb[1]', run_time: '1 second' },
      { example_id: './slow_spec.rb[1]', run_time: '2 seconds' }
    ].map { |example| example.merge status: 'passed' }
  end

  describe '#seconds_per_file' do
    subject { described_class.new.seconds_per_file }

    it 'returns an object of the specified provider class' do
      expect(subject).to eq(
        './fast_1_spec.rb' => 1.0,
        './fast_2_spec.rb' => 1.0,
        './fast_3_spec.rb' => 1.0,
        './slow_spec.rb' => 2.0
      )
    end
  end
end
