# frozen_string_literal: true

require 'spec_helper'

describe Flatware::Worker do
  let(:dispatch_endpoint) { 'ipc://test-dispatch' }
  let(:sink_endpoint) { 'ipc://test-sink' }
  let(:runner) { double 'Runner', run: nil }
  context 'when a worker is started' do
    let(:socket) { double 'Socket', recv: 'seppuku', send: nil }

    before do
      allow(Flatware).to receive(:socket) { socket }
    end

    it 'exits when dispatch is done' do
      described_class.new(1, runner, dispatch_endpoint, sink_endpoint).listen
    end
  end

  describe '::spawn' do
    it 'calls fork hooks' do
      fork do
        dispatch = Flatware.socket(ZMQ::REP, bind: dispatch_endpoint)
        dispatch.recv
        dispatch.send 'seppuku'
      end

      fork do
        Flatware.socket(ZMQ::PULL, bind: sink_endpoint)
      end

      Flatware.configuration.before_fork do
        pid = Process.pid
        fork do
          Flatware.socket(ZMQ::PUSH, bind: 'ipc://before')
                  .send([:before_fork, pid])
        end
      end

      Flatware.configuration.after_fork do |n|
        before = Flatware.socket(ZMQ::PULL, connect: 'ipc://before').recv
        push = Flatware.socket(ZMQ::PUSH, connect: 'ipc://after')
        push.send(before)
        push.send([:after_fork, n, Process.pid])
      end

      described_class.spawn(
        count: 1,
        runner: runner,
        dispatch: dispatch_endpoint,
        sink: sink_endpoint
      )

      s = Flatware.socket ZMQ::PULL, bind: 'ipc://after'

      expect(Array.new(2) { s.recv }).to match [
        [:before_fork, Process.pid],
        [:after_fork, 0, satisfy(&Process.pid.method(:!=))]
      ]
    end
  end
end
