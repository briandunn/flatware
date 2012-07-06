require 'spec_helper'

describe Flatware::StepResult do
  context 'with an exception' do
    let(:status) { :failed }
    let(:exception) { Exception.new }
    subject { described_class.new(status, exception) }

    it 'can be serialized' do
      expect { Marshal.load(Marshal.dump(subject)) }.to_not raise_error
    end
  end
end
