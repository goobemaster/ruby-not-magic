Given /I navigate to the ([a-zA-Z _]+) page/ do |page_name|
  page_name.gsub!(' ', '')
  @current_page = Pages::send(page_name)
  @current_page.load
end

Given /I deeplink to the ([a-zA-Z _]+) page:/ do |page_name, data_table|
  page_name.gsub!(' ', '')
  @current_page = Pages::send(page_name)
  @current_page.load(data_table.hashes[0])
end

Then /the current page must (not )?be the ([a-zA-Z _]+) page/ do |_not, page_name|
  page_name.gsub!(' ', '')
  _not = '_not' unless _not.nil?
  page = Pages::send(page_name)
  page.send "should#{_not}", be_displayed
  @current_page = page if _not.nil?
end
