# frozen_string_literal: true

require 'spec_helper'

describe Flatware::Worker do
  let(:sink) { double Flatware::Sink::Server }
  let(:runner) { double 'Runner', run: nil }

  context 'when a worker is started' do
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
        expect do
          worker.listen
        end.to raise_error(DRb::DRbConnError)
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

  describe '::spawn' do
    describe 'hooks' do
      after do
        Flatware.configuration.reset!
      end

      it 'calls fork hooks' do
        endpoint = 'drbunix:test'
        allow(sink).to receive_messages(
          before_fork: nil,
          after_fork: nil,
          ready: 'seppuku'
        )

        def sink.after_fork(*args)
          return @after_fork if args.empty?

          @after_fork = args
        end

        DRb.start_service(endpoint, sink)

        parent_pid = Process.pid

        Flatware.configuration.before_fork do
          sink.before_fork(parent_pid)

          expect(Process.pid).to eq parent_pid
        end

        Flatware.configuration.after_fork do |n|
          expect(n).to eq 0
          expect(Process.pid).not_to eq parent_pid
        end

        described_class.spawn(
          count: 1,
          runner: runner,
          sink: endpoint
        )
        Process.waitall
      end
    end
  end
end
