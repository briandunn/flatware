require 'spec_helper'
require 'flatware/rspec'

describe Flatware::RSpec do
  describe '.extract_jobs_from_args' do
    it 'divides the jobs evenly among the workers' do
      files = (?a..?z).to_a
      allow(::RSpec::Core::ConfigurationOptions).to receive(:new).and_return(instance_double(::RSpec::Core::ConfigurationOptions, configure: nil))
      allow(::RSpec::Core::Configuration).to receive(:new).and_return(instance_double(::RSpec::Core::Configuration, files_to_run: files))

      jobs = described_class.extract_jobs_from_args([], workers: 4)

      expect(jobs.map {|j| j.id.size}).to eq [7,7,6,6]
    end
  end
end
