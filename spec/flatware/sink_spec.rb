require 'spec_helper'

describe Flatware::Sink do
  before(:all) { Flatware.close }

  context 'when I have work to do, but am interupted' do
    let(:job) { double 'job', id: 'int.feature' }

    attr_reader :child_io

    before do
      unless @child_io = IO.popen("-")
        formatter = double 'Formatter'
        formatter.should_receive :summarize
        formatter.should_receive :summarize_remaining
        described_class.start_server [job], formatter
      end
    end

    it 'exits' do
      wait_until { !child_pids.empty? }
      pid = child_pids.first
      Process.kill 'INT', pid
      Process.wait pid
      child_io_output = child_io.read
      child_io_output.should match /SystemExit:/
      child_pids.should_not include pid
    end
  end

  context 'there is no work' do
    it 'sumarizes' do
      formatter = double 'Formatter'
      formatter.should_receive :summarize
      Flatware::Sink.start_server [], formatter
    end
  end

  context 'there is outstanding work' do
    context 'and a Result object is received' do
      it 'prints the result' do
        result    = Flatware::Result.new 'F'
        job       = Flatware::Job.new('foo', 'bar')
        formatter = double 'Formatter', result: nil, summarize: nil
        socket    = double 'Socket'
        socket.stub(:recv).and_return result, job
        Flatware::Fireable.stub(kill: nil, bind: nil)
        Flatware.stub socket: socket

        formatter.should_receive(:result).with result
        Flatware::Sink.start_server [job], formatter
      end
    end
  end
end
