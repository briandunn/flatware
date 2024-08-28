# frozen_string_literal: true

require 'etc'

# helper methods available in all steps
module Support
  def create_flunk_step_definition
    write_file 'features/step_definitions/flunky_steps.rb', <<-RB
      Then('flunk') { raise StandardError.new('hell') }
    RB
  end

  def create_sleep_step_definition
    write_file 'features/step_definitions/sleepy_steps.rb', <<-RB
      Then 'sleep for {int} seconds' do |seconds|
        puts seconds
        sleep seconds.to_f
      end
    RB
  end

  def all_output
    all_commands.map(&:output).join
  end

  def flatware_process
    all_commands.find { |command| command.commandline.include? 'flatware' }
  end

  def duration(&_block)
    started_at = Time.now
    yield
  ensure
    Time.now - started_at
  end
end
World(Support)

Given 'I am using a multi core machine' do
  expect(Etc.nprocessors).to be > 1
end

Given(
  'a cucumber suite with two features that each sleep for {int} second'
) do |sleepyness|
  create_sleep_step_definition
  2.times do |feature_number|
    write_file "features/feature_#{feature_number}.feature", <<-FEATURE
      Feature: sleeeeeep
      Scenario: I iz tired
        Then sleep for #{sleepyness} seconds
    FEATURE
  end
end

Given 'a sleepy cucumber suite' do
  step 'a cucumber suite with two features that each sleep for 1 second'
end

runners = Regexp.union %w[cucumber flatware]

When(/^I time the cucumber suite with (#{runners})$/) do |runner|
  @durations ||= {}
  commands = {
    'cucumber' => 'cucumber --format progress',
    'flatware' => "flatware cucumber -l -w #{max_workers}"
  }
  @durations[runner] = duration do
    run_command_and_stop(commands.fetch(runner))
  end
end

Then(/^(#{runners}) is the fastest$/) do |runner|
  expect(@durations.size).to be >= 2
  expect(@durations[runner]).to eq @durations.values.min
end

When(/^I run flatware(?: with "([^"]+)")?$/) do |args|
  command = ['flatware', args, '-w', max_workers].flatten.compact.join(' ')

  @duration = duration do
    run_command(command)
  end
end

Then 'the output contains the following:' do |string|
  expect(flatware_process).to have_output Regexp.new Regexp.escape string
end

Then(/^the output contains the following lines?( (\d+) times?)?:$/) do |n, string|
  normalize_space = ->(s) { s.split("\n").map(&:strip).join("\n") }
  expected_lines = normalize_space[string]
  actual_lines = normalize_space[sanitize_text(flatware_process.output)]
  expect(actual_lines).to include expected_lines
  expect(actual_lines.each_line.count { |line| line.strip == expected_lines }).to eq(n.to_i) if n
end

Given 'the following scenario:' do |scenario|
  create_flunk_step_definition

  write_file 'features/flunk.feature', <<-FEATURE
  Feature: flunk

  #{scenario}
  FEATURE
end

Given 'the following spec:' do |spec|
  write_file 'spec/spec_spec.rb', spec
end

Given(/^spec "([^"]*)" contains:$/) do |name, spec|
  write_file "spec/#{name}_spec.rb", spec
end

Then 'the output contains a backtrace' do
  trace = <<-TXT.gsub(/^ +/, '')
    features/flunk.feature:4:in `flunk'
  TXT

  expect(flatware_process).to have_output Regexp.new Regexp.escape trace
end

Then(/^I see that (\d+) (scenario|step)s? (?:was|where) run$/) do |count, thing|
  match = all_output.match(/^(?<count>\d+) #{thing}s?/)
  expect(match).to(be, "No match found for output #{all_output}")
  expect(match[:count].to_i).to eq count
end

Given 'a cucumber suite with two features that each fail' do
  create_flunk_step_definition
  2.times do |feature_number|
    write_file "features/failing_feature_#{feature_number}.feature", <<-FEATURE
    Feature: flunking

    Scenario: flunk
      Given flunk
    FEATURE
  end
end

Then 'the output contains a summary of failing features' do
  trace = <<-TXT.gsub(/^ +/, '')
    Failing Scenarios:
    features/failing_feature_0.feature:3 # Scenario: flunk
    features/failing_feature_1.feature:3 # Scenario: flunk
  TXT

  expect(flatware_process).to have_output Regexp.new Regexp.escape trace
end

Then 'I see log messages' do
  expect(flatware_process).to have_output Regexp.new 'flatware sink'
end
