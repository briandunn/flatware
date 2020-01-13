require 'spec_helper'

describe Flatware::Sink do
  let(:sink_endpoint) { 'druby://localhost:8787' }

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

      # disable rspec trap
      orig = trap 'INT', 'DEFAULT'

      unless (child_io = IO.popen('-'))
        allow(formatter).to receive(:summarize_remaining) do
          puts 'signal was captured'
        end
        described_class.start_server(**defaults.merge(jobs: [job]))
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
      child_pids = Flatware.pids { |cpid| cpid.ppid == Process.pid }
      expect(child_pids).to_not include pid
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
