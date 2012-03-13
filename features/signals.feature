Feature: Signals

  Scenario: TERM
    Given a worker is running
    And a dispatcher is running
    When I send the TERM signal to the dispatcher
    Then the dispatcher exits
    And the worker exits

  Scenario: output
    Given a worker is running
    And I dispatch a task that emits periods at regular intervals
