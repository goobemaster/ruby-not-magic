When /select ([a-zA-Z _]+) search category$/ do |search_category|
  @current_page.search_type.select search_category
end

And /type in search term "([a-zA-Z _]+)"$/ do |search_term|
  @current_page.search_term.set search_term
end

And /initiate the search by clicking on Go button$/ do
  @current_page.search_go.click
end

Given /search for "([a-zA-Z _]+)" ([a-zA-Z _]+)$/ do |search_term, search_category|
  step('Given I navigate to the Home page')
  step("When I select #{search_category} search category")
  step("And I type in search term \"#{search_term}\"")
  step('And I initiate the search by clicking on Go button')
  step('Then the current page must be the Search Result page')
end

And /verify results are displayed for term "([a-zA-Z _]+)"$/ do |search_term|
  @current_page.should have_no_zero_results_title
  @current_page.wait_for_results(10)
  @current_page.results.size.should be > 0

  id = 0
  @current_page.results.each { |result|
    result.title.text.should include search_term
    id += 1
    break if id > 3
  }
end

And /remember the title and author of result No. ?([1-9]+)$/ do |id|
  id = id.to_i - 1
  results_present = @current_page.results.size

  if results_present >= id
    result = @current_page.results[id]
    @author_remembered = result.author.text
    @title_remembered = result.title.text
    puts @author_remembered
    puts @title_remembered
  else
    raise "Cannot get result No. #{id}! There are only #{results_present} results displayed."
  end
end

When /click on the ([a-zA-Z _]+) of result No. ?([1-9]+)$/ do |element_name, id|
  id = id.to_i - 1
  results_present = @current_page.results.size

  if results_present >= id
    @current_page.results[id].send(element_name).click
  else
    raise "Cannot get result No. #{id}! There are only #{results_present} results displayed."
  end
end

And /^verify title and author are the same as were displayed on the results page$/ do
  @current_page.author.text.should include @author_remembered
  @current_page.title.text.should include @title_remembered
end

When /click on the look inside image$/ do
  @current_page.look_inside_v1.click if @current_page.has_look_inside_v1?
  @current_page.look_inside_v2.click if @current_page.has_look_inside_v2?
end

Then /wait for the look inside overlay to appear$/ do
  @current_page.wait_until_look_inside_overlay_visible(15)
end