require 'spec_helper'

describe Flatware::Sink do
  before(:all) { Flatware.close }

  context 'when I have work to do, but am interupted' do
    let(:job) { double 'job', id: 'int.feature' }

    let! :pid do
      fork { described_class.start_server [job], StringIO.new }
    end

    it 'exits' do
      wait_until { child_pids.include? pid }
      Process.kill 'INT', pid
      Process.wait pid
      child_pids.should_not include pid
    end
  end
end
