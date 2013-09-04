require 'ostruct'
A = OpenStruct.new.tap do |a|
  a.number = Transform /^(\d+(?:\.\d+)?)$/ do |num|
    num.to_f
  end
end

module Support
  def without_bundler_rubyopt(&block)
    rubyopt = ENV['RUBYOPT']
    ENV['RUBYOPT'] = ''
    val = yield
  ensure
    ENV['RUBYOPT'] = rubyopt
    return val
  end

  def create_flunk_step_definition
    write_file "features/step_definitions/flunky_steps.rb", <<-RB
      Then('flunk') { false.should be_true }
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

  def duration(&block)
    started_at = Time.now
    yield
  ensure
    return Time.now - started_at
  end
end
World(Support)

Given 'I am using a multi core machine' do
  Flatware::ProcessorInfo.count.should > 1
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

When /^I time the suite with (#{runners})$/ do |runner|
  @durations ||= {}
  commands = {
    'cucumber'  => 'cucumber --format progress',
    'fail-fast' => "flatware -l -w #{max_workers} --fail-fast",
    'flatware'  => "flatware -l -w #{max_workers}"
  }
  @durations[runner] = duration do
    run_simple commands[runner], false
  end
end

Then /^(#{runners}) is the fastest$/ do |runner|
  @durations.should have_at_least(2).values
  @durations[runner].should == @durations.values.min
end

When /^I run flatware(?: with "([^"]+)")?$/ do |args|
  command = (['flatware', '-w', max_workers] + [args]).compact.join(" ")
  @duration = duration do
    without_bundler_rubyopt { run_simple command }
  end
end

Then /^the suite finishes in less than (#{A.number}) seconds$/ do |seconds|
  @duration.should < seconds
end

Then /^the output contains the following:$/ do |string|
  assert_partial_output string, all_output
end

Given 'the following scenario:' do |scenario|
  create_flunk_step_definition

  write_file "features/flunk.feature", <<-FEATURE
  Feature: flunk

  #{scenario}
  FEATURE
end

Then 'the output contains a backtrace' do

  trace = <<-TXT.gsub(/^ +/, '')
    ./features/step_definitions/flunky_steps.rb:1:in `/^flunk$/'
    features/flunk.feature:4:in `Given flunk'
  TXT

  assert_partial_output trace, all_output
end

Then /^I see that (#{A.number}) (scenario|step)s? (?:was|where) run$/ do |count, thing|
  match = all_output.match(/^(?<count>\d+) #{thing}s?/)
  match.should be
  match[:count].to_i.should eq count
end

Then /^I see that (#{A.number}) (scenario|step)s? failed$/ do |count, thing|
  match = all_output.match /failed (?<count>\d+) #{thing}s?/
  match.should be
  match[:count].to_i.should eq count
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

  assert_partial_output trace, all_output
end

Then 'I see log messages' do
  assert_partial_output 'flatware options:', all_output
end

Then 'the failure list only includes one feature' do
  all_output.match /Failing Scenarios:\n(.+?)(?=\n\n)/m
  $1.split("\n").should have(1).feature
  assert_exit_status 1
end

Given /^an? (after|before) hook that will raise on (@.+)$/ do |side, tag|
  write_file "features/support/#{rand}.rb", <<-RB
    #{side.capitalize}('#{tag}') { 1.should eq 2 }
  RB
end
