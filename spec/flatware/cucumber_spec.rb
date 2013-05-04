require 'spec_helper'

describe Flatware::Cucumber do
  describe '.extract_jobs_from_args' do
    it 'creates a job for each feature file' do
      job_cue = described_class.extract_jobs_from_args %w[features -t@javascript]
      job_cue.jobs.map(&:args).uniq.should eq [%w[-t@javascript]]
    end
  end
end
