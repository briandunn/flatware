@wip
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
    And the output contains the following lines:
    """
Failures:

  1) fail should eq false
     Failure/Error: it { true.should eq false }

       expected: false
            got: true

       (compared using ==)
     # ./spec/spec_spec.rb:2:in `block (2 levels) in <top (required)>'
    """
