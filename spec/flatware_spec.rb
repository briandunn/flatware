require 'flatware'

describe Flatware::Job do
  describe "#process" do
    it "shovels self onto completed jobs" do
      completed_jobs = []

      job = Flatware::Job.new 0

      job.process(completed_jobs: completed_jobs)

      completed_jobs.include?(job).should be_true
    end
  end
end
