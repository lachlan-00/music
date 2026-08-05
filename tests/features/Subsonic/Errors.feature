Feature: Subsonic API - Error responses
  In order to write a client which fails gracefully
  As a user
  I need the server to report its errors in the way the Subsonic protocol defines

  Note: unlike the Ampache API, the Subsonic protocol carries its errors within an otherwise ordinary
  HTTP 200 response, with the status of the root element set to "failed".


  Scenario: An error is carried within a successful HTTP response
    When I specify the parameter "id" with value "folder-99999999"
    And I request the "getMusicDirectory" resource expecting an error
    Then the response status should be "200"
    And the error code should be "70" with message "file not found"


  Scenario: A successful request is not reported as an error
    When I request the "getMusicFolders" resource expecting an error
    Then the response status should be "200"
    And the response should not be an error


  Scenario: A folder which does not exist
    When I specify the parameter "id" with value "folder-99999999"
    And I request the "getMusicDirectory" resource expecting an error
    Then the error code should be "70" with message "file not found"


  Scenario: An album which does not exist
    When I specify the parameter "id" with value "album-99999999"
    And I request the "getMusicDirectory" resource expecting an error
    Then the error code should be "70" with message "Entity not found"


  Scenario: An ID which is not of any known type
    When I specify the parameter "id" with value "bogus-1"
    And I request the "getMusicDirectory" resource expecting an error
    Then the error code should be "0" with message "Unsupported id format bogus-1"


  Scenario: A mandatory parameter is missing
    When I request the "getMusicDirectory" resource expecting an error
    Then the error code should be "10" with message "Required parameter 'id' missing"


  Scenario: An action which the server does not know
    When I request the "noSuchAction" resource expecting an error
    Then the error code should be "0" with message "Requested action noSuchAction is not supported"
