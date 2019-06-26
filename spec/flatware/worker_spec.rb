# frozen_string_literal: true

require 'spec_helper'

describe Flatware::Worker do
  context 'when a worker is started' do
    let(:sink) { double Flatware::Sink::Server }
    let(:runner) { double 'Runner', run: nil }

    subject do
      described_class.new(1, runner, 'druby://test:12345')
    end

    before do
      allow(DRbObject).to receive(:new_with_uri).and_return(sink)
    end

    it 'exits when dispatch is done' do
      allow(sink).to receive(:ready).and_return('seppuku')
      subject.listen
    end

    context 'when we can not connect to the sink' do
      before do
        allow(sink).to receive(:ready).and_raise(DRb::DRbConnError)
      end

      it 'retries' do
        worker = subject
        worker.listen
        expect(sink).to have_received(:ready).exactly(10).times
      end
    end

    context 'when attepted job raises' do
      it 'marks the job as failed' do
        job = Flatware::Job.new
        allow(sink).to receive_messages(started: nil, finished: nil)
        allow(sink).to receive(:ready).and_return(job, 'seppuku')
        allow(runner).to receive(:run).and_raise(StandardError)
        subject.listen
        expect(sink).to have_received(:finished).with(
          having_attributes(failed?: true)
        )
      end
    end
  end
end
