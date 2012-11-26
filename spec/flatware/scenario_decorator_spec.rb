require 'spec_helper'

describe Flatware::ScenarioDecorator do
  let(:scenario) { stub file_colon_line: "features/file_line.feature:3", name: "scenario_name", status: :passed }
  let(:scenario_outline) { stub file_colon_line: "features/outline.feature:3", name: "outline_name" }
  let(:example_row) { stub scenario_outline: scenario_outline, status: :passed }

  context 'with scenario' do
    subject { Flatware::ScenarioDecorator.new(scenario) }
    it { subject.file_colon_line.should eq scenario.file_colon_line }
    it { subject.name.should eq scenario.name }
    it { subject.status.should eq scenario.status }
  end

  context 'with example row' do
    subject { Flatware::ScenarioDecorator.new(example_row) }
    it { subject.file_colon_line.should eq example_row.scenario_outline.file_colon_line }
    it { subject.name.should eq example_row.scenario_outline.name }
    it { subject.status.should eq example_row.status }
  end

end
