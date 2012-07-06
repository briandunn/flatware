Feature: Output
  In order to easily understand results
  I want familiar cucumber output

  Scenario: success
    Given a cucumber suite with two features that each sleep for 1 second
    When I run flatware
    Then the output contains the following:
    """
    ..

    2 scenarios (2 passed)
    2 steps (2 passed)
    """

  Scenario: failure
    Given the following scenario:
    """
    Scenario: failure output
      Given flunk
    """
    When I run flatware
    Then the output contains a backtrace
