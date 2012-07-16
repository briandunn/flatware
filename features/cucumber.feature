Feature: cucumber task
  Passes arguments on to cucumber

  Scenario:
    Given the following scenario:
    """
    @wip
    Scenario: wipped
    Given wips
    """
    When I run flatware with "cucumber -t~@wip"
    Then the output contains the following:
    """
    0 scenarios
    0 steps
    """

