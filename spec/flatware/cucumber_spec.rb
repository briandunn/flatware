require 'spec_helper'

describe Flatware::Cucumber do
  describe '.configure' do
    it 'coppies the arguments into each job' do
      config = described_class.configure %w[-t@javascript]
      expect(config.jobs.map(&:args).uniq).to eq [%w[-t@javascript]]
    end
  end
end
