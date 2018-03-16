require 'spec_helper'
describe Flatware::Stats do
  describe '#resolve' do
    let(:jobs) { [Flatware::Job.new('x.spec')] }

    let(:stats) do
      {
        'x.spec:3' => 1,
        'x.spec:7' => 2,
        'y.spec:1' => 3
      }
    end

    let(:stat_file_mtime) {Time.now}

    subject { described_class.new(stats, stat_file_mtime).resolve(jobs) }

    it 'expands jobs by file name' do
      expect(subject).to match_array [
        Flatware::Job.new('x.spec:3', duration: 1),
        Flatware::Job.new('x.spec:7', duration: 2)
      ]
    end

    context 'when the test file has been modified since the stats file' do
      # we can't since the tests may have moved around.
      let(:stat_file_mtime) {Time.now - 100}

      it 'does not expand the job to line numbers' do
        allow(jobs.first).to receive(:mtime) {Time.now}
        expect(subject).to match_array [Flatware::Job.new('x.spec')]
      end
    end
  end
end
