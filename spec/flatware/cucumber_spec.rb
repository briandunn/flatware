require 'spec_helper'
require 'aruba/rspec'

describe Flatware::Cucumber do
  describe '.configure' do
    it 'coppies the arguments into each job' do
      config = described_class.configure %w[-t@javascript]
      expect(config.jobs.map(&:args).uniq).to eq [%w[-t@javascript]]
    end
  end

  describe 'run', type: :aruba do
    let(:sink) do
      instance_double(Flatware::Sink::Server)
    end
    context 'with multiple scenarios in the same file' do
      it 'calls the steps the correct number of times' do
        sink = double Flatware::Sink::Server, progress: nil, checkpoint: nil
        allow(Flatware).to receive(:ran)

        write_file 'features/step_definitions/flunky_steps.rb', <<~RB
          Then('ran {int}', &Flatware.method(:ran))
        RB

        write_file 'features/feature_1.feature', <<~FEATURE
          Feature: 1
          Scenario: 1
            Then ran 1
          Scenario: 2
            Then ran 2
        FEATURE

        write_file 'features/feature_2.feature', <<~FEATURE
          Feature: 2
          Scenario: 3
            Then ran 3

        FEATURE

        Dir.chdir Pathname(Dir.pwd).join('tmp/aruba') do
          1.upto(2) do |i|
            described_class.run(
              "features/feature_#{i}.feature",
              args: [],
              sink: sink
            )
          end

          expect(Flatware).to have_received(:ran).with(1)
          expect(Flatware).to have_received(:ran).with(2)
          expect(Flatware).to have_received(:ran).with(3)
          expect(Flatware).to have_received(:ran).exactly(3).times
          expect(sink).to have_received(:progress).exactly(3).times
          expect(sink).to have_received(:checkpoint).exactly(2).times
        end
      end
    end
  end
end
