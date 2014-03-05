require 'spec_helper'

describe Flatware::Sink do
  before(:all) { Flatware.close }
  let(:endpoint) { 'ipc://sink-test' }

  context 'when I have work to do, but am interupted' do
    let(:job) { double 'job', id: 'int.feature' }

    attr_reader :child_io

    before do
      orig = trap 'INT', 'DEFAULT'
      unless @child_io = IO.popen("-")
        formatter = double 'Formatter', summarize_remaining: nil, summarize: nil, jobs: nil
        described_class.start_server [job], formatter, endpoint
      end
      trap 'INT', orig
    end

    it 'exits' do
      pid = child_io.pid
      Process.kill 'INT', pid
      wait pid
      child_io.read.should match /(SystemExit|Interrupt):/
      child_pids.should_not include pid
    end
  end

  context 'there is no work' do
    it 'sumarizes' do
      formatter = double 'Formatter', jobs: nil
      formatter.should_receive :summarize
      Flatware::Sink.start_server [], formatter, endpoint
    end
  end

  context 'there is outstanding work' do
    context 'and a Result object is received' do
      it 'prints the result' do
        result    = double
        job       = double failed?: false
        formatter = double 'Formatter', summarize: nil, jobs: nil
        socket    = double 'Socket'
        socket.stub(:recv).and_return [:progress, result], [:finished, job]
        Flatware::Fireable.stub(kill: nil, bind: nil)
        Flatware.stub socket: socket

        formatter.should_receive(:progress).with result
        formatter.should_receive(:finished).with job
        Flatware::Sink.start_server [job], formatter, endpoint
      end
    end
  end

  describe '#start_server' do
    let(:job) { double failed?: false }
    let(:formatter) { double 'Formatter', summarize: nil, jobs: nil, finished: nil }
    before do
      Flatware::Fireable.stub(kill: nil, bind: nil)
      socket = double 'Socket'
      socket.stub(:recv).and_return [:checkpoint, checkpoint], [:finished, job]
      Flatware.stub socket: socket
    end

    subject { described_class.start_server [job], formatter, endpoint }

    context 'when there are failures' do
      let(:checkpoint) { double 'Checkpoint', steps: [], scenarios: [], failures?: true }

      it { should be_false }
    end

    context 'when everything passes' do
      let(:checkpoint) { double 'Checkpoint', steps: [], scenarios: [], failures?: false }

      it { should be_true }
    end
  end
end
