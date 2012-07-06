Feature: Survives weird uses of gherkin

  Scenario: outlines with tables
    Given the following scenario:
    """
    Scenario Outline: Sanwiches
      Given I know you want to do it
      Then we make the following <food_item>:
        | Peanut Butter | Jelly  |  | time  |
        | Tuna          | Tartar |  | stuff |

    Scenarios:
      | food_item   | balls |
      | sandwitches |       |
    """
    When I run flatware
    Then the exit status should be 0
