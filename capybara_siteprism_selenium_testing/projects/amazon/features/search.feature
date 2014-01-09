Feature: Simple book search from the homepage

  @Name_results_page @smoke
  Scenario: Verify book search yields results
    Given I navigate to the Home page
    When I select Books search category
    And I type in search term "Harry Potter"
    And I initiate the search by clicking on Go button
    Then the current page must be the Search Result page
    And verify results are displayed for term "Harry Potter"

  @Name_title_and_author @smoke
  Scenario: Verify title and author are the same as were displayed on the results page
    Given I search for "Harry Potter" Books
    And remember the title and author of result No. 1
    When I click on the title of result No. 1
    Then the current page must be the Product Details page
    And verify title and author are the same as were displayed on the results page

  @Name_look_through @smoke
  Scenario: Verify the selected book can be looked through
    Given I deeplink to the Search Result page:
      | category   | keyword        |
      | stripbooks | Harry%20Potter |
    When I click on the title of result No. 1
    Then the current page must be the Product Details page
    When I click on the look inside image
    Then wait for the look inside overlay to appear