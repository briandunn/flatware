Feature: In order to compensate for impatience
  I want flatware to exit cleanly and with a useful message when interrupted


@non-zero
Scenario: clean exit
  Given a cucumber suite with two features that each sleep for 10 second
  When I run flatware with "cucumber" in background
  And I send the signal "INT" to the command started last
  Then the exit status should be 1
