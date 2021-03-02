require 'spec_helper'
require 'drb'

describe Flatware::Sink do
  let(:sink_endpoint) do
    server = TCPServer.new('127.0.0.1', 0)
    port = server.addr[1]
    server.close
    "druby://localhost:#{port}"
  end

  let! :formatter do
    double(
      'Formatter',
      ready: nil,
      summarize: nil,
      jobs: nil,
      progress: nil,
      finished: nil,
      summarize_remaining: nil
    )
  end

  let :defaults do
    {
      formatter: formatter,
      sink: sink_endpoint
    }
  end

  context 'when I have work to do, but am interupted' do
    it 'exits' do
      job = double 'job', id: 'int.feature'

      IO.popen('-') do |f|
        if f
          sleep 1
          Process.kill 'INT', f.pid

          expect(f.read).to match(/Interrupted/)

          child_pids = Flatware.pids { |cpid| cpid.ppid == Process.pid }
          expect(child_pids).to_not include f.pid
        else
          described_class.start_server(**defaults, jobs: [job])
        end
      end
    end
  end

  context 'there is no work' do
    it 'sumarizes' do
      server = described_class::Server.new jobs: [], **defaults
      server.ready(1)
      expect(formatter).to have_received :summarize
    end
  end

  context 'there is outstanding work' do
    context 'and a Result object is received' do
      it 'prints the result' do
        server = described_class::Server.new jobs: [], **defaults
        server.progress 'progress'

        expect(formatter).to have_received(:progress).with 'progress'
      end
    end
  end

  describe '#start_server' do
    subject do
      described_class.start_server(**defaults)
    end

    context 'returns the server result' do
      before do
        allow(described_class::Server).to receive(:new).and_return(
          instance_double(described_class::Server, start: :result)
        )
      end

      it { should eq(:result) }
    end
  end

  it 'groups jobs' do
    files = ('a'..'z').to_a.map(&Flatware::Job.method(:new))

    sink = described_class::Server.new(jobs: files, worker_count: 4, **defaults)

    expect(sink.jobs.map { |j| j.id.size }).to eq [7, 7, 6, 6]
  end
end
