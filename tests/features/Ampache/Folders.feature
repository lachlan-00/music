Feature: Ampache API - Folders
  In order to browse my library by its directory structure
  As a user
  I need to be able to walk the folder tree of my music library

  Note: `folders` is the standard action of API8, browsing the folder tree one level at a time. Our own flat
  listing of all the folders used to carry this name and is now called `folders_flat`, covered by the last
  scenarios here. Neither is restricted to a particular API version.

  Note: the folder IDs are those of the underlying file system nodes and differ between installations, so
  they are stored from an earlier response instead of being written out. The only fixed ID is the root, -1.


  Scenario: List the root of the library
    Given I am logged in with API version "8.0.0"
    When I request the "folders" resource
    Then the element "/root/total_count" should be "1"
    And the element "/root/folder/@id" should be "-1"
    And the element "/root/folder/parent" should be ""
    And the element "/root/folder/path" should be ""
    And the element "/root/folder/catalog" should be "1"
    And there should be 1 "/root/folder/items/item" elements
    And the element "/root/folder/items/item[1]/object_type" should be "folder"
    And the element "/root/folder/items/item[1]/title" should be "music"
    And the element "/root/folder/items/item[1]/path" should be "/music"
    And the element "/root/folder/items/item[1]/parent" should be "-1"


  Scenario: The root is reachable also by the ID -1 and by the path /
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "-1"
    And I request the "folders" resource
    Then the element "/root/folder/@id" should be "-1"
    When I specify the parameter "filter" with value "/"
    And I request the "folders" resource
    Then the element "/root/folder/@id" should be "-1"


  Scenario: Descend into a folder by its ID
    Given I am logged in with API version "8.0.0"
    When I request the "folders" resource
    And I store the "items/item[1]/@id" of the first result as "musicFolder"
    And I specify the parameter "filter" with value ":musicFolder"
    And I request the "folders" resource
    Then the element "/root/total_count" should be "13"
    And the element "/root/folder/title" should be "music"
    And the element "/root/folder/path" should be "/music"
    And the element "/root/folder/parent" should be "-1"
    And there should be 13 "/root/folder/items/item" elements
    And the element "/root/folder/items/item[1]/object_type" should be "song"


  Scenario: Descend into a folder by its path name
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "/music"
    And I request the "folders" resource
    Then the element "/root/total_count" should be "13"
    And the element "/root/folder/title" should be "music"


  Scenario: A path name is accepted also without the leading slash
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "music"
    And I request the "folders" resource
    Then the element "/root/folder/title" should be "music"


  Scenario: A path name of a wrong case is not found by default
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "MUSIC"
    And I request the "folders" resource expecting an error
    Then the error code should be "4704" of type "system"


  Scenario: A path name of a wrong case is found when the exact matching is off
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "MUSIC"
    And I specify the parameter "exact" with value "0"
    And I request the "folders" resource
    Then the element "/root/folder/title" should be "music"


  Scenario: The limit slices the items but leaves the total count untouched
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "/music"
    And I specify the parameter "limit" with value "3"
    And I request the "folders" resource
    Then the element "/root/total_count" should be "13"
    And there should be 3 "/root/folder/items/item" elements


  Scenario: The offset skips the leading items
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "/music"
    And I specify the parameter "offset" with value "11"
    And I request the "folders" resource
    Then the element "/root/total_count" should be "13"
    And there should be 2 "/root/folder/items/item" elements


  Scenario: Nothing was added after the given time
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "/music"
    And I specify the parameter "add" with value "2099-01-01"
    And I request the "folders" resource
    Then the element "/root/total_count" should be "0"


  Scenario: Everything was added after the beginning of time
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "/music"
    And I specify the parameter "add" with value "2000-01-01"
    And I request the "folders" resource
    Then the element "/root/total_count" should be "13"


  Scenario: Nothing was updated after the given time
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "/music"
    And I specify the parameter "update" with value "2099-01-01"
    And I request the "folders" resource
    Then the element "/root/total_count" should be "0"


  Scenario: Everything was updated after the beginning of time
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "/music"
    And I specify the parameter "update" with value "2000-01-01"
    And I request the "folders" resource
    Then the element "/root/total_count" should be "13"


  Scenario: An unknown folder ID is not found
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "99999999"
    And I request the "folders" resource expecting an error
    Then the error code should be "4704" of type "system"


  Scenario: A path outside of the music library is not found
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "/etc/passwd"
    And I request the "folders" resource expecting an error
    Then the error code should be "4704" of type "system"


  Scenario: The items are a plain array in the JSON format
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "/music"
    And I specify the parameter "limit" with value "1"
    And I request the "folders" resource in JSON format
    Then the JSON path "total_count" should be "13"
    And the JSON path "folder.path" should be "/music"
    And the JSON path "folder.items.0.object_type" should be "song"


  Scenario: The IDs and the catalog are rendered as strings in the JSON format
    Given I am logged in with API version "8.0.0"
    When I specify the parameter "filter" with value "/music"
    And I specify the parameter "limit" with value "1"
    And I request the "folders" resource in JSON format
    Then the JSON path "folder.id" should be a string
    And the JSON path "folder.parent" should be the string "-1"
    And the JSON path "folder.catalog" should be the string "1"
    And the JSON path "folder.items.0.id" should be a string
    And the JSON path "folder.items.0.parent" should be a string


  Scenario: The root of the library has no parent
    Given I am logged in with API version "8.0.0"
    When I request the "folders" resource in JSON format
    Then the JSON path "folder.id" should be the string "-1"
    And the JSON path "folder.parent" should have no value
    And the JSON path "folder.catalog" should be the string "1"
    And the JSON path "folder.items.0.parent" should be the string "-1"


  Scenario: The proprietary flat listing is served under its own name
    Given I am logged in with API version "8.0.0"
    When I request the "folders_flat" resource
    Then I should get:
      | name  |
      | music |


  Scenario: The flat listing is served also on the oldest API version
    Given I am logged in with API version "4.4.0"
    When I request the "folders_flat" resource
    Then I should get:
      | name  |
      | music |


  Scenario: The tree traversal is not restricted to API8 either
    Given I am logged in with API version "6.6.0"
    When I request the "folders" resource
    Then the element "/root/folder/@id" should be "-1"
    And the element "/root/folder/items/item[1]/title" should be "music"
