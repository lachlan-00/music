Feature: Ampache API - Smart lists
  In order to reach the built-in "All tracks" list with a client which navigates by smart lists
  As a user
  I need the smart list actions to work on it like they do on the original Ampache server

  The app has no user-definable smart lists, so the whole family operates on the single built-in list.
  Ampache identifies its smart lists as "smart_<n>" while our playlist actions use the bare id, and both
  spellings are accepted.


  Scenario: List all smart lists
    Given I am logged in with an auth token
    When I request the "smartlists" resource
    Then I should get:
      | @id | name       |
      | -1  | All tracks |


  Scenario: List smart lists matching a filter
    Given I am logged in with an auth token
    When I specify the parameter "filter" with value "All"
    And I request the "smartlists" resource
    Then I should get:
      | @id | name       |
      | -1  | All tracks |


  Scenario: List smart lists matching no filter
    Given I am logged in with an auth token
    When I specify the parameter "filter" with value "Nonexistent"
    And I request the "smartlists" resource
    Then I should get:
      | @id | name |


  Scenario: An exact filter does not match a partial name
    Given I am logged in with an auth token
    When I specify the parameter "filter" with value "All"
    And I specify the parameter "exact" with value "1"
    And I request the "smartlists" resource
    Then I should get:
      | @id | name |


  Scenario: Get the smart list by its bare id
    Given I am logged in with an auth token
    When I specify the parameter "filter" with value "-1"
    And I request the "smartlist" resource
    Then I should get:
      | @id | name       |
      | -1  | All tracks |


  Scenario: Get the smart list by the Ampache style id
    Given I am logged in with an auth token
    When I specify the parameter "filter" with value "smart_-1"
    And I request the "smartlist" resource
    Then I should get:
      | @id | name       |
      | -1  | All tracks |


  Scenario: Get the songs of the smart list
    Given I am logged in with an auth token
    When I specify the parameter "filter" with value "-1"
    And I specify the parameter "limit" with value "2"
    And I request the "smartlist_songs" resource
    Then I should get:
      | title           | artist                 |
      | Balrog Boogie   | Diablo Swing Orchestra |
      | Gunpowder Chant | Diablo Swing Orchestra |


  Scenario: An unknown smart list is not found
    Given I am logged in with API version "6.6.0"
    When I specify the parameter "filter" with value "smart_99"
    And I request the "smartlist" resource expecting an error
    Then the error code should be "4704" of type "system"


  Scenario: The built-in smart list can not be deleted
    Given I am logged in with API version "6.6.0"
    When I specify the parameter "filter" with value "-1"
    And I request the "smartlist_delete" resource expecting an error
    Then the error code should be "4703" of type "system"
