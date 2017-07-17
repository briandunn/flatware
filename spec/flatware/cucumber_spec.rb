require 'aruba/rspec'

describe Flatware::Cucumber do
  describe '.configure' do
    it 'coppies the arguments into each job' do
      config = described_class.configure %w[-t@javascript]
      expect(config.jobs.map(&:args).uniq).to eq [%w[-t@javascript]]
    end

    it 'does not duplicate a provided filename' do
      config = described_class.configure %w[features/marvelous.feature -t@javascript]
      expect(config.jobs.map(&:args).uniq).to eq [%w[-t@javascript]]
    end
  end

  describe 'run', type: :aruba do
    context 'with multiple scenarios in the same file' do
      it 'calls the steps the correct number of times' do
        sink = instance_double Flatware::Sink::Client, progress: nil, checkpoint: nil
        allow(Flatware::Sink).to receive(:client) { sink }
        allow(Flatware).to receive(:ran)

        write_file "features/step_definitions/flunky_steps.rb", <<~RB
          Then 'ran $n', &Flatware.method(:ran)
        RB

        write_file "features/feature_1.feature", <<~FEATURE
          Feature: 1
          Scenario: 1
            Then ran 1
          Scenario: 2
            Then ran 2
        FEATURE

        write_file "features/feature_2.feature", <<~FEATURE
          Feature: 2
          Scenario: 3
            Then ran 3

        FEATURE

        Dir.chdir Pathname(Dir.pwd).join('tmp/aruba')

        described_class.run('features/feature_1.feature', [])
        described_class.run('features/feature_2.feature', [])

        expect(Flatware).to have_received(:ran).with('1')
        expect(Flatware).to have_received(:ran).with('2')
        expect(Flatware).to have_received(:ran).with('3')
        expect(Flatware).to have_received(:ran).exactly(3).times
        expect(sink).to have_received(:progress).exactly(3).times
        expect(sink).to have_received(:checkpoint).exactly(2).times
      end
    end
  end
end
