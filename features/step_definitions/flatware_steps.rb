require 'ostruct'
A = OpenStruct.new.tap do |a|
  a.number = Transform /^(\d+(?:\.\d+)?)$/ do |num|
    num.to_f
  end
end

module Support
  def create_flunk_step_definition
    write_file "features/step_definitions/flunky_steps.rb", <<-RB
      Then('flunk') { raise StandardError.new('hell') }
    RB
  end

  def create_sleep_step_definition
    write_file "features/step_definitions/sleepy_steps.rb", <<-RB
      Then 'sleep for $seconds seconds' do |seconds|
        puts seconds
        sleep seconds.to_f
      end
    RB
  end

  def all_output
    all_commands.map(&:output).join
  end

  def flatware_process
    all_commands.find {|command| command.commandline.include? 'flatware' }
  end

  def run_simple(*args)
    begin
      super
    rescue ChildProcess::TimeoutError => e
      terminate_processes!
      puts all_output
      raise
    end
  end

  def duration(&block)
    started_at = Time.now
    yield
  ensure
    return Time.now - started_at
  end
end
World(Support)

Given 'I am using a multi core machine' do
  expect(Flatware::ProcessorInfo.count).to be > 1
end

Given /^a cucumber suite with two features that each sleep for (#{A.number}) seconds?$/ do |sleepyness|
  create_sleep_step_definition
  2.times do |feature_number|
    write_file "features/feature_#{feature_number}.feature", <<-FEATURE
      Feature: sleeeeeep
      Scenario: I iz tired
        Then sleep for #{sleepyness} seconds
    FEATURE
  end
end

Given 'more slow failing features than workers' do
  create_sleep_step_definition
  create_flunk_step_definition
  @scenario_count = ((max_workers * 2) + 1)
  ((max_workers * 2) + 1).times do |feature_number|
    write_file "features/feature_#{feature_number}.feature", <<-FEATURE
      Feature: slowly die
      Scenario: languish
        Given sleep for 0.5 seconds
        Then flunk
    FEATURE
  end
end

Given 'a sleepy cucumber suite' do
  step 'a cucumber suite with two features that each sleep for 1 second'
end

runners = Regexp.union %w[cucumber flatware fail-fast]

When /^I time the cucumber suite with (#{runners})$/ do |runner|
  @durations ||= {}
  commands = {
    'cucumber'  => 'cucumber --format progress',
    'fail-fast' => "flatware cucumber -l -w #{max_workers} --fail-fast",
    'flatware'  => "flatware cucumber -l -w #{max_workers}"
  }
  @durations[runner] = duration do
    run_simple commands[runner], false
  end
end

Then /^(#{runners}) is the fastest$/ do |runner|
  expect(@durations.size).to be >= 2
  expect(@durations[runner]).to eq @durations.values.min
end

When /^I run flatware(?: with "([^"]+)")?$/ do |args|
  command = ['flatware', args, '-w', max_workers].flatten.compact.join(" ")

  @duration = duration do
    run_simple command
  end
end

Then /^the suite finishes in less than (#{A.number}) seconds$/ do |seconds|
  expect(@duration).to be < seconds
end

Then /^the output contains the following:$/ do |string|
  expect(flatware_process).to have_output Regexp.new Regexp.escape string
end

Then /^the output contains the following lines:$/ do |string|
  normalize_space = ->(string) { string.split("\n").map(&:strip).join("\n") }
  expected_lines = normalize_space[string]
  actual_lines = normalize_space[sanitize_text(flatware_process.output)]
  expect(actual_lines).to include expected_lines
end

Given 'the following scenario:' do |scenario|
  create_flunk_step_definition

  write_file "features/flunk.feature", <<-FEATURE
  Feature: flunk

  #{scenario}
  FEATURE
end

Given 'the following spec:' do |spec|
  write_file 'spec/spec_spec.rb', spec
end

Then 'the output contains a backtrace' do

  trace = <<-TXT.gsub(/^ +/, '')
    features/flunk.feature:4:in `Given flunk'
  TXT

  expect(flatware_process).to have_output Regexp.new Regexp.escape trace
end

Then /^I see that (#{A.number}) (scenario|step)s? (?:was|where) run$/ do |count, thing|
  match = all_output.match(/^(?<count>\d+) #{thing}s?/)
  expect(match).to(be, "No match found for output #{all_output}")
  expect(match[:count].to_i).to eq count
end

Then 'I see that not all scenarios were run' do
  match = all_output.match(/^(?<count>\d+) scenarios?/)
  expect(@scenario_count).to be > match[:count].to_i
end

Then /^I see that (#{A.number}) (scenario|step)s? failed$/ do |count, thing|
  match = all_output.match /failed (?<count>\d+) #{thing}s?/
  expect(match).to be
  expect(match[:count].to_i).to eq count
end

Given /^a cucumber suite with two features that each fail$/ do
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
  trace = <<-TXT.gsub /^ +/, ''
    Failing Scenarios:
    features/failing_feature_0.feature:3 # Scenario: flunk
    features/failing_feature_1.feature:3 # Scenario: flunk
  TXT

  expect(flatware_process).to have_output Regexp.new Regexp.escape trace
end

Then 'I see log messages' do
  expect(flatware_process).to have_output Regexp.new 'flatware sink bind'
end

Then 'the failure list only includes one feature' do
  all_output.match /Failing Scenarios:\n(.+?)(?=\n\n)/m
  expect($1.split("\n").size).to eq 1
  expect(all_commands.map(&:exit_status)).to eq [1]
end

Given /^an? (after|before) hook that will raise on (@.+)$/ do |side, tag|
  write_file "features/support/#{rand}.rb", <<-RB
    #{side.capitalize}('#{tag}') { expect(1).to eq 2 }
  RB
end
