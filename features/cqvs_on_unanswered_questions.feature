Feature: In order to see error messages in the right place
  As a Data Provider or Data Provider Supervisor
  I want to specify CQVs stating a particular question must be answered based on other answers

  Background:
    Given I have the usual roles
    And I have hospitals
      | state | name      | abbrev |
      | NSW   | Left Wing | Left   |
    And I have users
      | email                         | first_name | last_name | role          | hospital  |
      | dataprovider@intersect.org.au | Data       | Provider  | Data Provider | Left Wing |
  # Setup questionnaire with two questions one must be present if other is something
    And I have a survey with name "MySurvey" and questions
      | question | question_type |
      | QChoice  | Choice        |
      | QText    | Text          |
    And question "QChoice" has question options
      | option_value | label     |
      | 1            | trigger   |
      | 0            | notrigger |
    And I have the following cross question validations
      | question | related | rule             | conditional_operator | conditional_constant | error_message                         |
      | QText    | QChoice | present_if_const | ==                   | 1                    | QText must be present if QChoice == 1 |

  Scenario: Warning shows up on entry screen
    Given I am ready to enter responses as dataprovider@intersect.org.au
    Then I should not see "QText must be present if QChoice == 1"

    When I store the following answers skipping assertion
      | question | answer  |
      | QChoice  | trigger |
      | QText    |         |
    Then I should see warning "QText must be present if QChoice == 1" for question "QText"

    When I store the following answers skipping assertion
      | question | answer    |
      | QChoice  | notrigger |
      | QText    |           |
    Then I should not see "QText must be present if QChoice == 1"

    When I store the following answers skipping assertion
      | question | answer    |
      | QChoice  | notrigger |
      | QText    | something |
    Then I should not see "QText must be present if QChoice == 1"

    When I store the following answers skipping assertion
      | question | answer    |
      | QChoice  | trigger   |
      | QText    | something |
    Then I should not see "QText must be present if QChoice == 1"

  Scenario: Warning shows up on response submission screen
    Given "dataprovider@intersect.org.au" created a response to the "MySurvey" survey with babycode "abc"
    And I am logged in as "dataprovider@intersect.org.au"
    And I am on the edit first response page
    And I store the following answers skipping assertion
      | question | answer  |
      | QChoice  | trigger |
      | QText    |         |

    When I am on the response summary page for abc
    Then I should not see "Submit"

    Given I am on the edit first response page
    And I store the following answers skipping assertion
      | question | answer  |
      | QChoice  | trigger |
      | QText    | present |

    When I am on the response summary page for abc
    And I press "Submit"
    Then I should see a confirmation message that "abc" for survey "MySurvey" has been submitted

  Scenario: Warning shows up on batch submission
    Given I am logged in as "dataprovider@intersect.org.au"
    And I uploaded the following batch file to the "MySurvey" survey in year "2005"
      | CYCLE_ID | QChoice | QText |
      | bad      | 1       |       |
    And the system processes the latest upload
    When I am on the list of batch uploads page
    Then I should see "batch_uploads" table with
      | Registration Type | Num records | Status       | Details                                                                                | Reports                       |
      | MySurvey          | 1           | Needs Review | The file you uploaded has one or more warnings. Please review the reports for details. | Summary Report\nDetail Report |
    And the last detail report should look like
      | CYCLE_ID | Column Name | Type    | Value | Message                               |
      | bad      | QText       | Warning |       | QText must be present if QChoice == 1 |

  Scenario: Warning is ok for valid batch submission
    Given I am logged in as "dataprovider@intersect.org.au"
    And I uploaded the following batch file to the "MySurvey" survey in year "2005"
      | CYCLE_ID | QChoice | QText   |
      | good     | 1       | present |
    And the system processes the latest upload
    When I am on the list of batch uploads page
    Then I should see "batch_uploads" table with
      | Registration Type | Num records | Status                 | Details                                    | Reports        |
      | MySurvey          | 1           | Processed Successfully | Your file has been processed successfully. | Summary Report |
