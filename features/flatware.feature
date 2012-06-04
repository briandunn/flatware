Feature: Distribute scenarios between workers
  In order to get feedback on my code as fast as possible
  I want to run more than one at a time

  Scenario:
    Given I am using a multi core machine
    And a cucumber suite with two features that each sleep for 1 second
    When I run flatware
    Then the suite finishes in less than 2 seconds

    @announce
  Scenario: output
    Given a cucumber suite with two features that each sleep for 1 second
    When I run flatware
    Then the output contains the following:
    """
    ..

    2 scenarios (2 passed)
    2 steps (2 passed)
    """
