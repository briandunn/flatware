require 'spec_helper'

describe Flatware::Sink::Signal do
  let(:formatter_queue) { Queue.new }

  let(:formatter) do
    queue = formatter_queue

    Class.new do
      define_method(:message, &queue.method(:push))
    end.new
  end

  let(:signal_blocks) { {} }

  let(:on_interrupt) do
    -> {}.tap do |block|
      allow(block).to receive(:call)
    end
  end

  before do
    allow(Process).to receive(:waitall)

    allow(Signal).to receive(:trap) do |signal, &block|
      signal_blocks[signal] = block
    end

    @subject = described_class.listen(formatter, &on_interrupt).tap do |instance|
      allow(instance).to receive(:abort)
    end
  end

  attr_reader :subject

  def send_signal(signal)
    signal_blocks.fetch(signal).call
  end

  shared_examples_for 'a signal initiated shutdown' do |expected_message|
    before do
      @messages = 2.times.map do
        Timeout.timeout(1, StandardError, 'formatter did not receive within 1 sec') do
          formatter_queue.pop.message
        end
      end
    end

    attr_reader :messages

    it 'aborts' do
      expect(subject).to have_received(:abort)
    end

    it 'tells the formatter to emit the signal message' do
      expect(messages).to match([match(expected_message), 'done.'])
    end

    it 'calls on_interrupt' do
      expect(on_interrupt).to have_received(:call)
    end

    it 'waits for workers' do
      expect(Process).to have_received(:waitall)
    end
  end

  describe 'on SIGINT' do
    before do
      send_signal('INT')
    end

    it_should_behave_like 'a signal initiated shutdown', 'Interrupted'
  end

  describe 'on SIGCLD' do
    context 'when a child failed' do
      before do
        allow(Process).to receive(:wait2).and_return(
          [nil, double(success?: true)],
          [nil, double(success?: false)],
          nil
        )

        send_signal('CLD')
      end

      it_should_behave_like 'a signal initiated shutdown', 'A worker died'
    end

    context 'when a child has not failed' do
      before do
        allow(Process).to receive(:wait2).and_return nil

        send_signal('CLD')
      end

      it 'does nothing' do
        expect(on_interrupt).to_not have_received(:call)
        expect(subject).to_not have_received(:abort)
        expect(formatter_queue).to be_empty
      end
    end
  end
end
