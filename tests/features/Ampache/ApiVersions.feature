Feature: Ampache API - Version negotiation
  In order to use a client written against a particular version of the protocol
  As a user
  I need the server to negotiate the API version and report the one it settled on

  Note: the negotiated version is bound to the session on the handshake, and the action `ping` reports it
  back in the elements `version` and `api`.

  Note: the protocol has no major version 7 at all, the version following 6 is 8.


  Scenario: The oldest supported version
    Given I am logged in with API version "4.4.0"
    When I request the "ping" resource
    Then the element "/root/api" should be "4.4.0"


  Scenario: An intermediate version
    Given I am logged in with API version "5.0.0"
    When I request the "ping" resource
    Then the element "/root/api" should be "5.6.0"


  Scenario: The version negotiated in the legacy six-digit format is reported in the same format
    Given I am logged in with API version "350001"
    When I request the "ping" resource
    Then the element "/root/api" should be "440000"


  Scenario: The newest version
    Given I am logged in with API version "8.0.0"
    When I request the "ping" resource
    Then the element "/root/api" should be "8.0.0"


  Scenario: The non-existent version 7 is served with the version 6 implementation
    Given I am logged in with API version "7.0.0"
    When I request the "ping" resource
    Then the element "/root/api" should be "6.8.0"


  Scenario: A version newer than the newest supported one is clamped
    Given I am logged in with API version "9.9.9"
    When I request the "ping" resource
    Then the element "/root/api" should be "8.0.0"
