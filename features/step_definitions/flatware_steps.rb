require 'ostruct'
A = OpenStruct.new.tap do |a|
  a.number = Transform /^(\d+)$/ do |num|
    num.to_i
  end
end

Given /^I am using a multi core machine$/ do
  `hostinfo` =~ /^(?<processors>\d+) processors are logically available\.$/
  @processors = $~[:processors].to_i
  @processors.should > 1
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

When 'I run flatware' do
  @started_at = Time.now
  @processors.times { run 'worker &' }
  run_simple 'dispatcher'
  assert_partial_output 'passed', all_output
end

Then /^the suite finishes in less than (#{A.number}) seconds$/ do |seconds|

  (Time.now - @started_at).should < seconds
end
