require 'spec_helper'

if Gem.loaded_specs['cucumber'].version < Gem::Version.new('2.0.0')
  describe Flatware::Cucumber::V1::Runner do
    context 'when there is an empty features dir' do
      it 'has no jobs' do
        cucumber_config = instance_double(::Cucumber::Cli::Configuration, feature_files: ['features'], feature_dirs: ['features'], parse!: nil )
        allow(::Cucumber::Cli::Configuration).to receive(:new) { cucumber_config }
        expect(described_class.configure([]).jobs).to be_empty
      end
    end
  end
end
