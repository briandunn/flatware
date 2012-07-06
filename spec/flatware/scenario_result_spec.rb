require 'spec_helper'
describe Flatware::ScenarioResult do
  let(:result) { described_class.new 'fooie', steps }

  context 'status' do
    subject { result.status }

    context 'with a failed step, and an undefined step' do
      let(:steps) { [stub(status: :failed), stub(status: :undefined)] }

      it { should == :failed }
    end

    context 'with an undefined and a passing step' do
      let(:steps) { [stub(status: :passed), stub(status: :undefined)] }

      it { should == :undefined }
    end

    context 'with all passing steps' do
      let(:steps) { [stub(status: :passed), stub(status: :passed)] }

      it { should == :passed }
    end
  end
end
