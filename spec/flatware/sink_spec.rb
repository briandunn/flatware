require 'spec_helper'

describe Flatware::Sink do
  before { Flatware.close }
  let(:sink_endpoint) { 'ipc://sink-test' }
  let(:dispatch_endpoint) { 'ipc://dispatch-test' }
  let! :formatter do
    double 'Formatter', ready: nil,
      summarize: nil, jobs: nil, progress: nil, finished: nil, summarize_remaining: nil
  end

  let :defaults do
    {
      formatter: formatter,
      sink: sink_endpoint,
      dispatch: dispatch_endpoint
    }
  end

  context 'when I have work to do, but am interupted' do
    it 'exits' do
      job = double 'job', id: 'int.feature'

      # disable rspec trap
      orig = trap 'INT', 'DEFAULT'

      unless child_io = IO.popen("-")
        allow(formatter).to receive(:summarize_remaining) { puts 'signal was captured' }
        described_class.start_server defaults.merge(jobs: [job])
      end

      trap 'INT', orig
      pid = child_io.pid
      sleep 0.1
      retries = 0

      begin
        Process.kill 'INT', pid
        wait pid
      rescue Timeout::Error
        retries += 1
        if retries < 3
          retry
        else
          exit(1)
        end
      end
      expect(child_io.read).to match(/signal was captured/)
      expect(child_pids).to_not include pid
    end
  end

  context 'there is no work' do
    it 'sumarizes' do
      allow(DRb).to receive(:start_service).and_return nil
      allow(DRb).to receive(:thread).and_return []
      server = described_class::Server.new defaults.merge(jobs: [])
      server.ready(1)
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

        described_class.start_server defaults.merge(jobs: [job])
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
      described_class.start_server defaults.merge(jobs: [job])
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

  it 'groups jobs' do
    files = (?a..?z).to_a.map(&Flatware::Job.method(:new))

    sink = described_class::Server.new defaults.merge(jobs: files, worker_count: 4)

    expect(sink.jobs.map {|j| j.id.size}).to eq [7,7,6,6]
  end
end
