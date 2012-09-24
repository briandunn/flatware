require 'ostruct'
A = OpenStruct.new.tap do |a|
  a.number = Transform /^(\d+)$/ do |num|
    num.to_i
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

  def processors
    @processors ||= `hostinfo`.match(/^(?<processors>\d+) processors are logically available\.$/)[:processors].to_i
  end

  def duration(&block)
    started_at = Time.now
    yield
  ensure
    return Time.now - started_at
  end
end
World(Support)

Given /^I am using a multi core machine$/ do
  processors.should > 1
end

Given /^a cucumber suite with two features that each sleep for (#{A.number}) seconds?$/ do |sleepyness|
  2.times do |feature_number|
    write_file "features/feature_#{feature_number}.feature", <<-FEATURE
      Feature: sleeeeeep
      Scenario: I iz tired
        Then sleep for #{sleepyness} seconds
    FEATURE
  end
  write_file "features/step_definitions/sleepy_steps.rb", <<-RB
    Then /^sleep for (\\d+) seconds$/ do |seconds|
      sleep seconds.to_i
    end
  RB
end

Given 'a sleepy cucumber suite' do
  step 'a cucumber suite with two features that each sleep for 1 second'
end

When /^I time the suite with (cucumber|flatware)$/ do |runner|
  @durations ||= {}
  commands = {
    'cucumber' => 'cucumber --format progress',
    'flatware' => 'flatware cucumber'
  }
  @durations[runner] = duration do
    run_simple commands[runner], false
  end
  assert_exit_status 0
end

Then 'flatware is faster' do
  @durations['flatware'].should < @durations['cucumber']
end

When /^I run flatware(?: with "([^"]+)")?$/ do |args|
  @duration = duration do
    without_bundler_rubyopt { run_simple ['flatware', args].compact.join(" ") }
  end
end

Then /^the suite finishes in less than (#{A.number}) seconds$/ do |seconds|
  @duration.should < seconds
end

Then /^the output contains the following:$/ do |string|
  assert_partial_output string, all_output
end

Given 'the following scenario:' do |scenario|
  write_file "features/step_definitions/flunky_steps.rb", <<-RB
    Then('flunk') { false.should be_true }
  RB

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
