require 'spec_helper'

describe Flatware::Cucumber do
  describe '.configure' do
    it 'coppies the arguments into each job' do
      config = described_class.configure %w[-t@javascript]
      expect(config.jobs.map(&:args).uniq).to eq [%w[-t@javascript]]
    end

    context 'when there is an empty features dir' do
      it 'has no jobs' do
        cucumber_config = instance_double(::Cucumber::Cli::Configuration, feature_files: ['features'], feature_dirs: ['features'], parse!: nil)
        allow(::Cucumber::Cli::Configuration).to receive(:new) { cucumber_config }
        expect(described_class.configure([]).jobs).to be_empty
      end
    end
  end
end
