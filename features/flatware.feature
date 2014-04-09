Feature: Distribute scenarios between workers
  In order to get feedback on my code as fast as possible
  I want to run more than one at a time

  Scenario: cucumber
    Given I am using a multi core machine
    And a sleepy cucumber suite
    When I time the cucumber suite with cucumber
    And I time the cucumber suite with flatware
    Then flatware is the fastest
