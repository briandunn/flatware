Feature: cucumber task
  Passes arguments on to cucumber

  Background:
    Given the following scenario:
    """
    @wip
    Scenario: wipped
    Given wips
    """

  Scenario: provide only cucumber options
    When I run flatware with "cucumber -t~@wip"
    Then the output contains the following:
    """
    0 scenarios
    0 steps
    """

    @non-zero
  Scenario: provide erroneous cucumber options
    When I run flatware with "cucumber --foo bar"
    Then the output contains the following:
    """
    invalid option: --foo
    """
