class LookInside < SitePrism::Section
end

class ProductDetails < SitePrism::Page
  set_url '/{product_name}/dp/{product_id}'
  set_url_matcher /\/[a-zA-Z0-9 _\-]+\/dp\/[0-9A-Z]+/

  element :title, 'span#btAsinTitle'
  element :author, "a[id^='contributorNameTrigger']"
  element :look_inside_v1, 'img#imgBlkFront'
  element :look_inside_v2, 'img#main-image'

  section :look_inside_overlay, LookInside, "div#sitbReaderPlaceholder"
end