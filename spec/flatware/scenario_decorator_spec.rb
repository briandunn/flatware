require 'spec_helper'

describe Flatware::Cucumber::ScenarioDecorator do
  let :scenario do
    double 'Scenario', file_colon_line: "features/file_line.feature:3",
      name: "scenario_name", status: :passed, exception: 'scenario exception'
  end

  let :scenario_outline do
    double 'Scenario Outline', file_colon_line: "features/outline.feature:3",
      name: "outline_name"
  end

  let :example_row do
    double 'ExampleRow', scenario_outline: scenario_outline,
      status: :passed, exception: 'example row exception'
  end

  context 'with scenario' do
    subject { described_class.new(scenario) }
    its(:file_colon_line) { should eq scenario.file_colon_line }
    its(:name) { should eq scenario.name }
    its(:status) { should eq scenario.status }
    its(:exception) { should eq 'scenario exception' }
  end

  context 'with example row' do
    subject { described_class.new(example_row) }
    its(:file_colon_line) { should eq example_row.scenario_outline.file_colon_line }
    its(:name) { should eq example_row.scenario_outline.name }
    its(:status) { should eq example_row.status }
    its(:exception) { should eq 'example row exception' }
  end

end
