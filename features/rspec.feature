Feature: rspec task

  @non-zero
  Scenario: failure messages
    Given the following spec:
      """
      describe "fail" do
      it { expect(true).to eq false }
      end
      """
    When I run flatware with "rspec -l"
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

      1) fail is expected to eq false
      Failure/Error: it { expect(true).to eq false }

      expected: false
      got: true

      (compared using ==)
      """
    And the output contains the following:
      """
      # ./spec/spec_spec.rb:2:in `block (2 levels) in <top (required)>'
      """

  Scenario: it behaves like
    Given the following spec:
      """
      class Rick
        def drunk?
          true
        end
      end

      class PickleRick < Rick
      end

      shared_examples_for Rick do
        it('drinks') { expect(subject).to be_drunk }
      end

      describe PickleRick do
        it_behaves_like Rick
      end
      """
    When I run flatware with "rspec"
    Then the output contains the following:
      """
      1 example, 0 failures
      """
