require 'spec_helper'
require 'flatware/dispatcher'

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

      before { Flatware::Fireable.bind }

      let!(:task) { Flatware.socket ZMQ::REP, bind: Flatware::Dispatcher::PORT }

      context 'when the publisher sends the die message' do

        it 'the worker exits' do
          task.recv
          Flatware::Fireable.kill
          Process.waitall
          child_pids.should_not include pid
        end
      end
    end
  end
end
