require 'spec_helper'

describe Flatware::Cucumber::StepResult do
  context 'with an exception' do
    let(:status) { :failed }
    let(:exception) { Exception.new }
    let(:duration) { 0 }
    subject { described_class.new(status, exception, duration) }

    it 'can be serialized' do
      expect { Marshal.load(Marshal.dump(subject)) }.to_not raise_error
    end
  end
end
