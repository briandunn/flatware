require 'spec_helper'

describe Flatware::Sink do
  before(:all) { Flatware.close }
  let(:sink_endpoint) { 'ipc://sink-test' }
  let(:dispatch_endpoint) { 'ipc://dispatch-test' }
  let :formatter do
    double 'Formatter', ready: nil,
      summarize: nil, jobs: nil, progress: nil, finished: nil, summarize_remaining: nil
  end

  context 'when I have work to do, but am interupted' do
    attr_reader :child_io
    let(:job) { double 'job', id: 'int.feature' }
    let(:formatter) { double 'Formatter', summarize_remaining: nil, summarize: nil, jobs: nil }

    before do
      # disable rspec trap
      orig = trap 'INT', 'DEFAULT'
      unless @child_io = IO.popen(?-)
        allow(formatter).to receive(:summarize_remaining) { puts 'signal was captured' }
        described_class.start_server jobs: [job], formatter: formatter, sink: sink_endpoint, dispatch: dispatch_endpoint
      end

      trap 'INT', orig
    end

    it 'exits' do
      pid = child_io.pid
      sleep 0.1
      retries = 0

      begin
        Process.kill 'INT', pid
        wait pid
      rescue Timeout::Error
        retries += 1
        retry if retries < 3
      end
      expect(child_io.read).to match(/signal was captured/)
      expect(child_pids).to_not include pid
    end
  end

  context 'there is no work' do
    it 'sumarizes' do
      worker = Flatware.socket ZMQ::REQ, connect: dispatch_endpoint
      worker.send 'ready'
      described_class.start_server jobs: [], formatter: formatter, sink: sink_endpoint, dispatch: dispatch_endpoint
      expect(formatter).to have_received :summarize
    end
  end

  context 'there is outstanding work' do
    context 'and a Result object is received' do
      it 'prints the result' do
        job       = OpenStruct.new failed?: false
        socket    = Flatware.socket(ZMQ::PUSH, connect: sink_endpoint)
        socket.send [:progress, 'progress']
        socket.send [:finished, job]

        described_class.start_server jobs: [job], formatter: formatter, sink: sink_endpoint, dispatch: dispatch_endpoint
        expect(formatter).to have_received(:progress).with 'progress'
        expect(formatter).to have_received(:finished).with job
      end
    end
  end

  describe '#start_server' do
    let(:job) { OpenStruct.new failed?: false }

    before do
      socket = Flatware.socket(ZMQ::PUSH, connect: sink_endpoint)
      socket.send [:checkpoint, checkpoint]
      socket.send [:finished, job]
    end

    subject do
      described_class.start_server jobs: [job], formatter: formatter, sink: sink_endpoint, dispatch: dispatch_endpoint
    end

    context 'when there are failures' do
      let(:checkpoint) { OpenStruct.new steps: [], scenarios: [], failures?: true }

      it { should_not be }
    end

    context 'when everything passes' do
      let(:checkpoint) { OpenStruct.new steps: [], scenarios: [], failures?: false }

      it { should be }
    end
  end
end
