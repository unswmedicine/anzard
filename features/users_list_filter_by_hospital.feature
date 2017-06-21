Feature: Administer users
  In order to allow users to access the system
  As an administrator
  I want to administer users

  Background:
    Given I have the usual roles
    And I have clinics
      | state | name       |
      | NSW   | Clinic 2 |
      | Vic   | Clinic 3 |
      | Vic   | H4         |
      | NSW   | Left Wing  |
      | Vic   | Right Wing |
      | Vic   | Only Wing  |
    And I have users
      | email                 | first_name | last_name | role                     | clinic   |
      | fred@intersect.org.au | Fred       | Jones     | Data Provider Supervisor | Left Wing  |
      | dan@intersect.org.au  | TheManDan  | Superuser | Administrator            |            |
      | anna@intersect.org.au | Anna       | Smith     | Data Provider            | Right Wing |
      | bob@intersect.org.au  | Bob        | Smith     | Data Provider Supervisor | Left Wing  |
      | joe@intersect.org.au  | Joe        | Bloggs    | Data Provider            | H4         |
    And I am logged in as "dan@intersect.org.au"
    When I am on the list users page


  Scenario: Filter by clinic
    Then the "Filter by clinic" nested select should contain
      |     | ANY, None                             |
      | NSW | Clinic 2, Left Wing                 |
      | Vic | H4, Clinic 3, Only Wing, Right Wing |
    When I select "Left Wing" from "Filter by clinic"
    And I press "Filter"
    Then I should see "users" table with
      | First name | Last name | Email                 | Role                     | Clinic        | Status |
      | Bob        | Smith     | bob@intersect.org.au  | Data Provider Supervisor | Left Wing (NSW) | Active |
      | Fred       | Jones     | fred@intersect.org.au | Data Provider Supervisor | Left Wing (NSW) | Active |
    And "Left Wing" should be selected in the "Filter by clinic" select

  Scenario: Filter by clinic = NONE
    When I select "None" from "Filter by clinic"
    And I press "Filter"
    Then I should see "users" table with
      | First name | Last name | Email                | Role          | Clinic |
      | TheManDan  | Superuser | dan@intersect.org.au | Administrator | (None)   |
    And "None" should be selected in the "Filter by clinic" select

  Scenario: Change from clinic filter back to ANY
    When I select "Left Wing" from "Filter by clinic"
    And I press "Filter"
    When I select "ANY" from "Filter by clinic"
    And I press "Filter"
    Then I should see "users" table with
      | First name | Last name | Email                 | Role                     | Clinic         | Status |
      | Anna       | Smith     | anna@intersect.org.au | Data Provider            | Right Wing (Vic) | Active |
      | Bob        | Smith     | bob@intersect.org.au  | Data Provider Supervisor | Left Wing (NSW)  | Active |
      | TheManDan  | Superuser | dan@intersect.org.au  | Administrator            | (None)           | Active |
      | Fred       | Jones     | fred@intersect.org.au | Data Provider Supervisor | Left Wing (NSW)  | Active |
      | Joe        | Bloggs    | joe@intersect.org.au  | Data Provider            | H4 (Vic)         | Active |

  Scenario: Sort while filtered by clinic retains filter
    When I select "Left Wing" from "Filter by clinic"
    And I press "Filter"
    Then I should see "users" table with
      | First name | Last name | Email                 | Role                     | Clinic        | Status |
      | Bob        | Smith     | bob@intersect.org.au  | Data Provider Supervisor | Left Wing (NSW) | Active |
      | Fred       | Jones     | fred@intersect.org.au | Data Provider Supervisor | Left Wing (NSW) | Active |
    When I follow "Last name"
    Then I should see "users" table with
      | First name | Last name | Email                 | Role                     | Clinic        | Status |
      | Fred       | Jones     | fred@intersect.org.au | Data Provider Supervisor | Left Wing (NSW) | Active |
      | Bob        | Smith     | bob@intersect.org.au  | Data Provider Supervisor | Left Wing (NSW) | Active |
    And "Left Wing" should be selected in the "Filter by clinic" select

  Scenario: Filter by clinic while sorted retains sort
    When I follow "Last name"
    And I select "Left Wing" from "Filter by clinic"
    And I press "Filter"
    Then I should see "users" table with
      | First name | Last name | Email                 | Role                     | Clinic        | Status |
      | Fred       | Jones     | fred@intersect.org.au | Data Provider Supervisor | Left Wing (NSW) | Active |
      | Bob        | Smith     | bob@intersect.org.au  | Data Provider Supervisor | Left Wing (NSW) | Active |

