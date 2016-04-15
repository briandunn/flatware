require 'flatware'
require 'flatware/cucumber'

describe Flatware::Cucumber::Formatter do

  let(:mother) { double 'Mother', steps: [] }
  let(:exception) { Exception.new }
  let(:sink) { double 'Sink', progress: nil }

  before do
    stub_const 'Flatware::Sink', double('Sink', client: sink)
      allow(mother).to receive(:scenarios).and_return [],
        [double('Scenario', file_colon_line: 'file:11', status: nil, exception: nil, name: nil)]

    formatter.scenario_name nil, nil, 'file:11'
  end

  subject(:formatter) { described_class.new mother }

  context 'when an exception happens in a step' do
    it 'does not mark the scenario as failing outside of a step' do
      checkpoint = nil
      allow(sink).to receive(:checkpoint) {|cp| checkpoint = cp }

      formatter.before_step
      formatter.exception(exception, :failed)
      formatter.after_step

      formatter.after_features

      expect(checkpoint.scenarios.select(&:failed_outside_step?).size).to eq 0
    end
  end

  context 'when an exception happens in an outline table row' do
    it 'does not mark the scenario as failing outside of a step' do
      checkpoint = nil
      allow(sink).to receive(:checkpoint) {|cp| checkpoint = cp }

      formatter.before_outline_table
      formatter.before_table_cell
      formatter.exception(exception, :failed)
      formatter.after_table_cell
      formatter.after_outline_table

      formatter.after_features

      expect(checkpoint.scenarios.select(&:failed_outside_step?).size).to eq 0
    end
  end

  context 'when an exception happens outside a step' do
    it 'marks the scenario as failing outside of a step' do
      checkpoint = nil
      allow(sink).to receive(:checkpoint) {|cp| checkpoint = cp }

      formatter.exception(exception, :failed)

      formatter.after_features

      expect(checkpoint.scenarios.select(&:failed_outside_step?).size).to eq 1
    end
  end
end
