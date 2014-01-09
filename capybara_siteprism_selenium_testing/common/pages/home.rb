class Home < SitePrism::Page
  set_url '/'
  set_url_matcher /\/?$/

  element :search_type, "select[id='searchDropdownBox']"
  element :search_term, "input[id='twotabsearchtextbox']"
  element :search_go, "input[value='Go']"
end