Feature: Submitted Cycle Ids
  In order to keep track of the submitted codes
  As a data provider or data provider supervisor
  I want to view list of submitted cycle ids

  Background:
    Given I have the usual roles
    And I have hospitals
      | state | name       |
      | NSW   | Hospital 2 |
      | Vic   | Hospital 3 |
      | Vic   | H4         |
      | NSW   | Left Wing  |
      | Vic   | Right Wing |
      | Vic   | Only Wing  |
    And I have users
      | email                 | first_name | last_name | role                     | hospital   |
      | fred@intersect.org.au | Fred       | Jones     | Data Provider Supervisor | Left Wing  |
      | dan@intersect.org.au  | TheManDan  | Superuser | Administrator            |            |
      | anna@intersect.org.au | Anna       | Smith     | Data Provider            | Right Wing |
      | bob@intersect.org.au  | Bob        | Smith     | Data Provider Supervisor | Left Wing  |
      | joe@intersect.org.au  | Joe        | Bloggs    | Data Provider            | H4         |
    And I have a survey with name "main"
    And I have a survey with name "followup"
    And hospital "Right Wing" has submitted the following cycle ids
      | year | cycle_id | form |
      | 2012 | abcd      | main |
    And hospital "H4" has submitted the following cycle ids
      | year | cycle_id | form     |
      | 2012 | cycle1     | main     |
      | 2012 | cycle5     | followup |
      | 2011 | cycle6     | main     |
    And hospital "Left Wing" has submitted the following cycle ids
      | year | cycle_id | form     |
      | 2011 | cycle2     | followup |
      | 2012 | cycle3     | main     |
      | 2010 | cycle4     | main     |

  Scenario: Data provider can view the list of submitted cycle ids
    Given I am logged in as "fred@intersect.org.au"
    When I am on the home page
    And I follow "Submitted Cycle Ids"
    Then I should be on the submitted cycle ids page
    And I should see the following cycle ids
    | form     | year | cycle_id |
    | followup | 2011 | cycle2     |
    | main     | 2012 | cycle3     |
    | main     | 2010 | cycle4     |

  Scenario: Administrator can not see the submitted cycle ids link
    Given I am logged in as "dan@intersect.org.au"
    When I am on the home page
    Then I should not see link "Submitted Cycle Ids"

  Scenario: Administrator will see error when opening submitted cycle ids
    Given I am logged in as "dan@intersect.org.au"
    Then I should get a security error when I visit the submitted cycle ids page

