Feature: child processes close
  The parent process must ensure that all processes it forks are closed

  Scenario: ensure that all processes are closed
    Given a cucumber suite with a feature that fails
    When I run flatware with "--child-pids"
    Then I see that none of the child pids exist as processes
