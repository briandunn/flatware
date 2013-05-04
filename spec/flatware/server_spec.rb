require 'spec_helper'

describe Flatware::Sink::Server do
  let(:server) { described_class.new job_cue, $stdout, $stderr }

  describe '#start' do
    context 'with no jobs' do
      let(:job_cue) { [] }
      it 'returns nil' do
        server.start.should eq nil
      end
    end

    context 'with a job' do
      let(:job_cue) { [1] }

      it 'serves all jobs and returns a summary of all work' do
        server.start.should eq 'hai'
      end
    end
  end
end
