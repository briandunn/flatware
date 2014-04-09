Feature: rspec task

  @non-zero
  Scenario: failure messages
    Given the following spec:
    """
    describe "fail" do
      it { true.should eq false }
    end
    """
    When I run `flatware rspec`
    Then the output contains the following:
    """
    F
    """
    And the output contains the following:
    """
    1 example, 1 failure
    """
