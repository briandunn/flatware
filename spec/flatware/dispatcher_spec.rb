require 'spec_helper'

describe Flatware::Dispatcher do
  context 'when a dispatcher is started' do

    before do
      @pid = fork do
        $0 = described_class.to_s
        described_class.start [:job]
      end
    end

    attr_reader :pid

    context 'when a publisher has bound the die socket' do

      before { Flatware::Fireable::bind }

      context 'when the publisher sends the die message' do

        it 'the dispatcher exits' do
          wait_until { child_pids.include? pid }
          Flatware::Fireable::kill
          exit_statuses = Process.waitall.map(&:last)
          exit_statuses.all?(&:success?).should be
          child_pids.should_not include pid
        end
      end
    end
  end
end
