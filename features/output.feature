Feature: Output
  In order to easily understand results
  I want familiar cucumber output

  Scenario: success
    Given a cucumber suite with two features that each sleep for 1 second
    When I run flatware with "cucumber"
    Then the output contains the following:
    """
    ..

    2 scenarios (2 passed)
    2 steps (2 passed)
    """

    @non-zero
  Scenario: failure
    Given the following scenario:
    """
    Scenario: failure output
      Given flunk
    """
    When I run flatware with "cucumber"
    Then the output contains a backtrace

    @non-zero
  Scenario: features dir does not exist
    When I run flatware with "cucumber"
    Then the output contains the following:
    """
    Please create some feature files in the features directory.
    """

    @non-zero
  Scenario: multiple failure
    Given a cucumber suite with two features that each fail
    When I run flatware with "cucumber"
    Then the output contains a summary of failing features

    @non-zero
  Scenario: outlines
    Given the following scenario:
    """
    Scenario Outline: old McDonnald
      Given <animal>
      When on his farm there was a <animal>
      Then there was a <sound> <sound> here and a <sound> <sound> there

    Scenarios:
      | animal | sound |
      | cow    | moo   |
      | flunk  | boom  |
    """
    When I run flatware with "cucumber"
    Then the output contains the following:
    """
    UUUFUU
    """
    And the output contains the following:
    """
    2 scenarios (1 failed, 1 undefined)
    6 steps (1 failed, 5 undefined)
    """

  Scenario: backgrounds
    Given the following scenario:
    """
    Background:
      Given some stuff

    Scenario:
      Then there are two steps
    """
    When I run flatware with "cucumber"
    Then the output contains the following:
    """
    1 scenario (1 undefined)
    2 steps (2 undefined)
    """

    @non-zero @wip
  Scenario: Failures in hooks print a backtrace
    Given the following scenario:
    """
    @fail-after
    Scenario Outline: Fail after outline
      Then later I <action>!

    Scenarios:
      | action |
      | failed |

    @fail-before
    Scenario Outline: Fail before outline
      But before I <action>!

    Scenarios:
      | action |
      | failed |

    # Scenario: Pass
    #   Then this one is in the clear

    Scenario: Fail
      Then flunk

    @fail-before
    Scenario: Fail in before hook
      Then this one is doomed!

    @fail-after
    Scenario: Fail in after hook
      Then this one is doomed!
    """
    And an after hook that will raise on @fail-after
    And a before hook that will raise on @fail-before
    When I run flatware with "cucumber"
    Then I see that 5 scenarios where run
    And I see that 4 scenarios failed
