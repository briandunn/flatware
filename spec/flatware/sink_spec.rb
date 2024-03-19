require 'spec_helper'
require 'drb'
require 'timeout'

describe Flatware::Sink do
  let!(:sink_endpoint) do
    server = TCPServer.new('127.0.0.1', 0)
    port = server.addr[1]
    server.close
    "druby://0.0.0.0:#{port}"
  end

  let! :formatter do
    double(
      'Formatter',
      finished: nil,
      jobs: nil,
      progress: nil,
      ready: nil,
      summarize: nil,
      summarize_remaining: nil
    ).tap do |formatter|
      allow(formatter).to receive(:summarize_remaining, &method(:puts))
    end
  end

  let :defaults do
    {
      formatter: formatter,
      sink: sink_endpoint
    }
  end

  def connect
    Timeout.timeout(2) do
      sleep 0.1
      DRbObject.new_with_uri(sink_endpoint)
    rescue DRb::DRbConnError
      retry
    end
  end

  def fork_server(&block)
    IO.popen('-') do |f|
      if f
        connect.ready(1)
        block.call(f)
        Process.waitall
      else
        described_class.start_server(**defaults, jobs: [job])
      end
    end
  end

  context 'when I have work to do' do
    let(:job) { Flatware::Job.new('int.feature') }

    context 'but a worker dies' do
      it 'explains and exits non-zero' do
        fork_server do |server|
          Process.kill 'CLD', server.pid

          expect(server.read).to match(/A worker died/).and(match(/int\.feature/))

          Process.wait(server.pid)
          expect(Process.last_status).to_not be_success
        end
      end
    end

    context 'but am interupted' do
      it 'explains and exits non-zero' do
        fork_server do |server|
          Process.kill 'INT', server.pid

          expect(server.read).to match(/Interrupted/).and(match(/int\.feature/))

          Process.wait(server.pid)
          expect(Process.last_status).to_not be_success
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
