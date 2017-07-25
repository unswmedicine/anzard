Feature: Delete Data Entry Forms in Progress
    In order to remove incomplete Data Entry Forms
    As a Data Provider Supervisor
    I want to be able to delete Data Entry Forms in progress

    Background:
        Given I have a user "data.provider@intersect.org.au" with role "Data Provider" and clinic "RPA"
        Given I am logged in as "data.supervisor@intersect.org.au" and have role "Data Provider Supervisor" and I'm linked to clinic "RPA"
        And I have a survey with name "survey" and questions
          | question  | mandatory |
          | Choice Q1 |    true   |
          | Choice Q2 |    true   |
        Given "data.provider@intersect.org.au" created a response to the "survey" survey with id "123" and cycleid "cycleid123"
        Given "data.provider@intersect.org.au" created a response to the "survey" survey with id "456" and cycleid "cycleid456"


    Scenario: I can see a delete button when logged in as a Data Provider Supervisor
        When I am on the home page
        Then I should see "responses" table with
          | Cycle Id   | Registration Type | Created By  |
          | cycleid123 | survey            | Fred Bloggs |
          | cycleid456 | survey            | Fred Bloggs |
        And I should see link "Delete"


    Scenario: I can not see a delete button when logged in as a Data Provider
        Given I am logged in as "data.provider@intersect.org.au"
        When I am on the home page
        Then I should see "responses" table with
          | Cycle Id   | Registration Type | Created By  |
          | cycleid123 | survey            | Fred Bloggs |
          | cycleid456 | survey            | Fred Bloggs |
        And I should not see link "Delete"


    @javascript
    Scenario: I can delete an incomplete response
        When I am on the home page
        Then I should see "responses" table with
          | Cycle Id   | Registration Type | Created By  |
          | cycleid123 | survey            | Fred Bloggs |
          | cycleid456 | survey            | Fred Bloggs |
        And I follow "Delete"
        Then I should see "You are about to delete this form in progress for CYCLE_ID cycleid123. This action cannot be undone. Are you sure you want to delete this form?"
        And I wait for 2 seconds
        And I follow "Delete" within "#confirm_delete_123"
        Then I should see "responses" table with
          | Cycle Id   | Registration Type | Created By  |
          | cycleid456 | survey            | Fred Bloggs |
