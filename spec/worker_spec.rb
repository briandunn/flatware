require 'spec_helper'

describe Flatware::Worker do
  context 'when a worker is started' do
    let! :pid do
      fork { described_class.listen! }
    end

    it 'is a child of this process' do
      child_pids.should include pid
      Process.kill 6, pid
    end

    context 'when a publisher has bound the die socket' do
      let(:context) { ZMQ::Context.new }

      let! :die do
        context.socket(ZMQ::PUB).tap do |s|
          s.bind 'ipc://die'
        end
      end

      let! :task do
        context.socket(ZMQ::REP).tap do |s|
          s.bind 'ipc://dispatch'
        end
      end

      before { task.recv }
      after { [die, task, context].each &:close }

      context 'when the publisher sends the die message' do

        it 'the worker exits' do
          die.send 'seppuku'
          Process.waitall
          child_pids.should_not include pid
        end
      end
    end
  end
end
