require 'flatware/checkpoint'

describe Flatware::Checkpoint do
  describe "#process" do
    it "should shovel self onto checkpoints passed in by reference" do
      checkpoints, steps, scenarios = [], [], []

      checkpoint = described_class.new(steps, scenarios)
      checkpoint.process(checkpoints: checkpoints)

      checkpoints.include?(checkpoint).should be_true
    end
  end
end
