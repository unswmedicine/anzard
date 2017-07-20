Feature: Create Response
  In order to enter data
  As a data provider
  I want to start a new survey and save my answers

  Background:
    Given I have the usual roles
    And I have a user "data.provider@intersect.org.au" with role "Data Provider"
    And I have year of registration range configured as "2000" to "2010"
    And I have a survey with name "Survey B" and questions
      | question   |
      | Question B |
    And I have a survey with name "Survey A" and questions
      | question   |
      | Question A |
    And I am logged in as "data.provider@intersect.org.au"

  Scenario: Creating a response
    When I create a response for "Survey A" with cycle id "ABC123" and year of registration "2001"
    Then I should see "Data entry form created"
    And I should see "Survey A - Cycle Id ABC123 - Year of Registration 2001"
    And I should see "Question A"
    And I should not see "Question B"

  Scenario: Correct survey types are in the dropdown
    When I am on the new response page
    Then the "Registration type" select should contain
      | Please select |
      | Survey A      |
      | Survey B      |

  Scenario: Correct years are in the year of reg dropdown
    When I am on the new response page
    Then the "Year of registration" select should contain
      | Please select |
      | 2000          |
      | 2001          |
      | 2002          |
      | 2003          |
      | 2004          |
      | 2005          |
      | 2006          |
      | 2007          |
      | 2008          |
      | 2009          |
      | 2010          |

  Scenario: Try to create without selecting survey type
    When I create a response for "Please select" with cycle id "ABC123"
    Then I should see "Registration type can't be blank" within the form errors

  Scenario: Try to create without selecting year of registration
    When I create a response for "Survey A" with cycle id "ABC123" and year of registration "Please select"
    Then I should see "Year of registration can't be blank" within the form errors

  Scenario: Try to create with duplicate cycle id
    Given I create a response for "Survey A" with cycle id "ABC123"
    When I create a response for "Survey A" with cycle id "ABC123"
    Then I should see "Cycle ID ABC123 has already been used." within the form errors

  Scenario: Try to create with duplicate cycle id with surrounding spaces
    Given I create a response for "Survey A" with cycle id "ABC123"
    When I create a response for "Survey A" with cycle id " ABC123 "
    Then I should see "Cycle ID ABC123 has already been used." within the form errors

  Scenario: Responses should be ordered by cycle id on the home page
    Given I create a response for "Survey A" with cycle id "C"
    Given I create a response for "Survey A" with cycle id "D"
    Given I create a response for "Survey A" with cycle id "B"
    Given I create a response for "Survey A" with cycle id "A"
    Given I create a response for "Survey A" with cycle id "AB"
    When I am on the home page
    Then I should see "responses" table with
      | Cycle Id |
      | A         |
      | AB        |
      | B         |
      | C         |
      | D         |
