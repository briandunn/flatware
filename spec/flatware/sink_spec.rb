require 'spec_helper'

describe Flatware::Sink do
  before(:all) { Flatware.close }

  context 'when I have work to do, but am interupted' do
    let(:job) { double 'job', id: 'int.feature' }

    attr_reader :child_io

    before do
      unless @child_io = IO.popen("-")
        described_class.start_server [job]
      end
    end

    it 'exits' do
      wait_until { !child_pids.empty? }
      pid = child_pids.first
      Process.kill 'INT', pid
      Process.wait pid
      child_io.read.should match /SystemExit:/
      child_pids.should_not include pid
    end
  end

  context 'there is no work' do
    it 'sumarizes' do
      Flatware::Summary.any_instance.should_receive :summarize
      Flatware::Sink.start_server []
    end
  end

  context 'there is outstanding work' do
    context 'and a Result object is received' do
      it 'prints the result' do
        result = Flatware::Result.new 'F'
        job    = Flatware::Job.new('foo', 'bar')
        out    = StringIO.new
        socket = double 'Socket'
        socket.stub(:recv).and_return result, job
        Flatware::Fireable.stub(kill: nil, bind: nil)
        Flatware.stub socket: socket

        Flatware::Sink.start_server [job], out

        out.tap(&:rewind).read.should =~ /^F/
      end
    end
  end
end
