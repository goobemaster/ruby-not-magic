class Result < SitePrism::Section
  element :image, "div[class='image imageContainer']"
  element :title, "span[class='lrg bold']"
  element :author, "span[class='med reg'] a"
end

class SearchResult < SitePrism::Page
  set_url '/s/ref=nb_sb_noss_1?url=search-alias%3D{category}&field-keywords={keyword}'
  set_url_matcher /\/s\/.*url=search-alias.*/

  element :zero_results_title, "h1[id='noResultsTitle']"
  sections :results, Result, "div[id^='result_'][class$='prod celwidget']"
end