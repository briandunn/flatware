require 'spec_helper'

describe Flatware::Cucumber::ScenarioDecorator do
  context 'with scenario' do
    let :scenario do
      double 'Scenario', file_colon_line: "features/file_line.feature:3",
        name: "scenario_name", status: :passed, exception: 'scenario exception'
    end

    subject { described_class.new(scenario) }

    it 'delegates file_colon_line to the scenario' do
      expect(subject.file_colon_line).to eq scenario.file_colon_line
    end

    it 'delegates name to the scenario' do
      expect(subject.name).to eq scenario.name
    end

    it 'delegates status to the scenario' do
      expect(subject.status).to eq scenario.status
    end

    it 'delegates exception to scenario' do
      expect(subject.exception).to eq 'scenario exception'
    end
  end

  context 'with example row' do
    let :scenario_outline do
      double 'Scenario Outline', file_colon_line: "features/outline.feature:3",
        name: "outline_name"
    end

    let :example_row do
      double 'ExampleRow', scenario_outline: scenario_outline,
        status: :passed, exception: 'example row exception'
    end

    subject { described_class.new(example_row) }

    it 'delegates file_colon_line to the scenario outline of the example row' do
      expect(subject.file_colon_line).to eq "features/outline.feature:3"
    end

    it 'has the name of the scenario outline' do
      expect(subject.name).to eq "outline_name"
    end

    it 'has the status of the example row' do
      expect(example_row.status).to eq :passed
    end

    it 'has the exception of the example row' do
      expect(subject.exception).to eq 'example row exception'
    end
  end
end
