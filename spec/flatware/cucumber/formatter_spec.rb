require 'spec_helper'

describe Flatware::Cucumber::Summary do
  let(:summary) { described_class.new steps, io }
  let(:io) { StringIO.new }
  let(:passed) { stub status: :passed, failed?: false, scenario_id: 'happy:10' }
  let(:failed) { stub status: :failed, failed?: true, scenario_id: 'sad:10', exception: exception }

  let(:exception) do
    stub backtrace: %w'backtrace', message: 'message', class: 'class'
  end

  let(:steps) { [] }
  before { summary.summarize }
  subject { io.tap(&:rewind).read.gsub /\e[^m]+m/, '' }

  context 'with a passed scenario' do
    let(:steps) { [passed] }

    it { should include %[1 scenario (1 passed)] }
  end

  context 'with one passed and one failed scenario' do
    let(:steps) { [passed, failed] }
    it 'displays the count' do
      should include %[2 scenarios (1 passed, 1 failed)]
    end

    it 'contains the backtrace' do
      should include 'backtrace'
    end
  end
end

describe Flatware::Cucumber::StepResult do
  context 'with an exception' do
    let(:status) { :failed }
    let(:exception) { Exception.new }
    subject { described_class.new(status, exception) }

    it 'can be serialized' do
      expect { Marshal.load(Marshal.dump(subject)) }.to_not raise_error
    end
  end
end
