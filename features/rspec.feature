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
      Failure/Error: it { expect(true).to eq false }

      expected: false
      got: true

      (compared using ==)
      """
    And the output contains the following:
      """
      # ./spec/spec_spec.rb:2:in
      """
    And the output contains the following:
      """
      block (2 levels) in <top (required)>'
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

  Scenario: group deprecations
    Given spec "1" contains:
      """
      describe 'some deprecations' do
        it { ''.stub(:foo) }
      end
      """
    And spec "2" contains:
      """
      describe 'other deprecations' do
        it { ''.should be_empty }
      end
      """
    When I run flatware with "rspec"
    Then the output contains the following line 1 time:
      """
      Deprecation Warnings:
      """
    And the output contains the following line:
      """
      2 deprecation warnings total
      """
    And the output contains the following line:
      """
      2 examples, 0 failures
      """

  @non-zero
  Scenario: failure outside of examples
    Given the following spec:
      """
      throw :a_fit
      describe 'fits' do
        it('already threw one')
      end
      """
    When I run flatware with "rspec"
    Then the output contains the following line:
      """
      uncaught throw :a_fit
      """

    And the output contains the following line:
      """
      0 examples, 0 failures, 1 error occurred outside of examples
      """
