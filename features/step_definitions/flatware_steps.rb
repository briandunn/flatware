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

When 'I run flatware' do
  processors.times { run 'worker &' }
  @duration = duration do
    # loading bundler slows down the SUT processes too much for us to detect
    # parallelization.
    # TODO: make the tests aware of when the workers check in, and start the
    # timer after that
    without_bundler_rubyopt { run_simple 'dispatcher' }
  end
  # assert_partial_output 'passed', all_output
end

Then /^the suite finishes in less than (#{A.number}) seconds$/ do |seconds|
  @duration.should < seconds
end

Then /^the output contains the following:$/ do |string|
    assert_partial_output string, all_output
end
