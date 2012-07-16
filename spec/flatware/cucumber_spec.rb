require 'spec_helper'

describe Flatware::Cucumber do
  describe '.extract_jobs_from_args' do
    it 'creates a job for each feature file' do
      jobs = described_class.extract_jobs_from_args %w[features -t@javascript]
      jobs.map(&:args).uniq.should eq [%w[-t@javascript]]
    end
  end
end
