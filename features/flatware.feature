Feature: Run features on all local cores
	In order to get feedback on my code as fast as possible
	My features will run on all my local cores

  Scenario: Distribute scenarios between the cores
    Given I am using a dual core machine 
    And I am in the root directory of a spork bootsrapped cucumber app
    And my app has two scenarios
    When I run "flatware Cucumber"
    Then I should see 
    """
    Using Cucumber
    Using Cucumber
    """
    When I run "cucumber --drb"
    Then each spork should run one scenario
    And I should see the cucumber output
