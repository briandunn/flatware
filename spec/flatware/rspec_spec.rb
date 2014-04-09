require 'spec_helper'
require 'flatware/rspec'

describe Flatware::RSpec do
  describe '.extract_jobs_from_args' do
    it 'returns a job for a file' do
      actual = described_class.extract_jobs_from_args ['spec/some_spec.rb']
      expect(actual).to eq [Flatware::Job.new('spec/some_spec.rb', [])]
    end

    it 'returns a bunch of jobs for a bunch of files' do
      actual = described_class.extract_jobs_from_args ['spec/some_spec.rb', 'spec/another_spec.rb']
      job_one = Flatware::Job.new('spec/some_spec.rb', [])
      job_two = Flatware::Job.new('spec/another_spec.rb', [])
      actual.should =~ [job_one, job_two]
    end
  end

  describe '.run' do

  end
end
