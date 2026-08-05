Feature: Subsonic API - Folder browsing
  In order to browse my music collection by its directory structure
  As a user
  I need to be able to navigate the folder hierarchy instead of the artist hierarchy

  Note: the app presents two synthetic music folders, one for each of the two ways of browsing. This covers
  the "Folders" one; the "Artists" one is covered by GetIndexes.feature and GetMusicDirectory.feature.

  Note: the folder IDs are those of the underlying file system nodes and differ between installations, so
  they are stored from an earlier response instead of being written out.


  Scenario: List the music folders
    When I request the "getMusicFolders" resource
    Then I should get XML with "musicFolder" entries:
      | id | name    |
      | -1 | Artists |
      | -2 | Folders |


  Scenario: Without a music folder, the library is indexed by artist
    When I request the "getIndexes" resource
    Then I should get XML with "index/artist" entries:
      | name                     |
      | Diablo Swing Orchestra   |
      | Pascal Boiseau (Pascalb) |
      | Simon Bowman             |


  Scenario: Index the library by folder
    When I specify the parameter "musicFolderId" with value "-2"
    And I request the "getIndexes" resource
    Then I should get XML with "index" entries:
      | name |
      | M    |
    And the XML result should contain "index/artist" entries:
      | name  |
      | music |


  Scenario: List the contents of a folder
    Given I specify the parameter "musicFolderId" with value "-2"
    And I request the "getIndexes" resource
    And I store the attribute "id" from the first "index/artist" XML element as "folderId"
    When I specify the parameter "id" with the stored value of "folderId"
    And I request the "getMusicDirectory" resource
    Then I should get XML containing 13 "child" entries


  Scenario: The songs of a folder carry their path within the library
    Given I specify the parameter "musicFolderId" with value "-2"
    And I request the "getIndexes" resource
    And I store the attribute "id" from the first "index/artist" XML element as "folderId"
    When I specify the parameter "id" with the stored value of "folderId"
    And I request the "getMusicDirectory" resource
    Then I should get XML with "child" entries:
      | path                                  |
      | /music/1048292-[AudioTrimmer.com].mp3 |
      | /music/1048293-[AudioTrimmer.com].mp3 |
      | /music/1048300-[AudioTrimmer.com].mp3 |
      | /music/1050077-[AudioTrimmer.com].mp3 |
      | /music/1050078-[AudioTrimmer.com].mp3 |
      | /music/23969-[AudioTrimmer.com].mp3   |
      | /music/23975-[AudioTrimmer.com].mp3   |
      | /music/23976-[AudioTrimmer.com].mp3   |
      | /music/391002-[AudioTrimmer.com].mp3  |
      | /music/391005-[AudioTrimmer.com].mp3  |
      | /music/391010-[AudioTrimmer.com].mp3  |
      | /music/391013-[AudioTrimmer.com].mp3  |
      | /music/391014-[AudioTrimmer.com].mp3  |


  Scenario: The library path is carried also by the songs of a search result
    When I specify the parameter "query" with value "Nuance"
    And I request the "search3" resource
    Then the XML result should contain "song" entries:
      | title   | path                                |
      | Aç      | /music/23975-[AudioTrimmer.com].mp3 |
      | Médiane | /music/23969-[AudioTrimmer.com].mp3 |
      | Vagues  | /music/23976-[AudioTrimmer.com].mp3 |
