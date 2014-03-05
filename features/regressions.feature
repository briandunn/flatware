Feature: Survives weird uses of gherkin

  Scenario: outlines with tables
    Given the following scenario:
    """
    Background:
      Given the pubas is grand

    Scenario Outline: Sanwiches
      Given I know you want to do it
      Then we make the following <food_item>:
        | Peanut Butter | Jelly  |  | time  |
        | Tuna          | Tartar |  | stuff |

    Scenarios:
      | food_item   | balls |
      | sandwitches |       |
      | pancakes    |       |
    """
    When I run flatware
    Then the exit status should be 0
    And I see that 2 scenarios where run
    And I see that 6 steps where run

    @non-zero
  Scenario: fail with feedback when features do not exist
    When I run flatware
    Then the exit status should be 1
