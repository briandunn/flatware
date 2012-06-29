require 'spec_helper'

describe Flatware::Cucumber::Summary do
  let(:summary) { described_class.new scenarios, steps, io }
  let(:io) { StringIO.new }
  let(:passed) { stub status: :passed }
  let(:failed) { stub status: :failed }
  let(:steps) { [] }
  before { summary.summarize }
  subject { io.tap(&:rewind).read.gsub /\e[^m]+m/, '' }

  context 'with a passed scenario' do
    let(:scenarios) { [passed] }

    it { should include %[1 scenario (1 passed)] }
  end

  context 'with one passed and one failed scenario' do
    let(:scenarios) { [passed, failed] }
    let(:steps) { [stub(exception: exception, status: :failed)] }
    let(:exception) do
      stub backtrace: %w'backtrace', message: 'message', class: 'class'
    end

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
      expect { YAML.load(YAML.dump(subject)) }.to_not raise_error
    end
  end
end
