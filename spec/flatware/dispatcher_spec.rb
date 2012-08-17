require 'spec_helper'

describe Flatware::Dispatcher do
  context 'when a dispatcher is started' do
    before :all do
      @pid = fork { described_class.start [:job] }
    end

    attr_reader :pid

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

      after { [die, context].each &:close }

      context 'when the publisher sends the die message' do

        it 'the dispatcher exits' do
          die.send 'seppuku'
          Process.waitall
          child_pids.should_not include pid
        end
      end
    end
  end
end
