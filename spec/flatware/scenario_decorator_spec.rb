require 'spec_helper'

describe Flatware::ScenarioDecorator do
  let(:scenario) { double 'Scenario', file_colon_line: "features/file_line.feature:3", name: "scenario_name", status: :passed }
  let(:scenario_outline) { double 'Scenario Outline', file_colon_line: "features/outline.feature:3", name: "outline_name" }
  let(:example_row) { double 'ExampleRow', scenario_outline: scenario_outline, status: :passed }

  context 'with scenario' do
    subject { Flatware::ScenarioDecorator.new(scenario) }
    its(:file_colon_line) { should eq scenario.file_colon_line }
    its(:name) { should eq scenario.name }
    its(:status) { should eq scenario.status }
  end

  context 'with example row' do
    subject { Flatware::ScenarioDecorator.new(example_row) }
    its(:file_colon_line) { should eq example_row.scenario_outline.file_colon_line }
    its(:name) { should eq example_row.scenario_outline.name }
    its(:status) { should eq example_row.status }
  end

end
