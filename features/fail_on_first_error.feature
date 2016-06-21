@non-zero
Feature: fail on first error
  In order to get feedback sooner
  I can opt out of running the whole suite if there is a problem

  Scenario:
    Given more slow failing features than workers
    When I run flatware with " --fail-fast"
    Then I see that not all scenarios were run

  Scenario: failing fast is faster
    Given more slow failing features than workers
    When I time the suite with fail-fast
    And I time the suite with flatware
    Then fail-fast is the fastest
