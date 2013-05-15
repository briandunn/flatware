require 'flatware/checkpoint'
describe Flatware::Checkpoint do
  subject(:checkpoint) { described_class.new [], scenarios }

  describe "#failures?" do
    subject { checkpoint.failures? }

    context "when all scenarios passed" do
      let :scenarios do
        [
          double('scenario',
            status: :passed,
            file_colon_line: nil,
            name: nil
          )
        ]
      end

      it { should be_false }
    end

    context "when any scenarios failed" do
      let :scenarios do
        [
          double('scenario',
            status: :failed,
            file_colon_line: nil,
            name: nil
          )
        ]
      end

      it { should be_true }
    end
  end
end
