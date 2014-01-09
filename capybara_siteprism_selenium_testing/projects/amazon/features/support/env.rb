require 'capybara'
require 'capybara/cucumber'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'site_prism'

Dir[File.dirname(__FILE__) + '/../../../../common/pages/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/../../../../common/*.rb'].each {|file| require file }

# - GENERAL -
Capybara.run_server = false
Capybara.default_wait_time = 20
Capybara.ignore_hidden_elements = false

# - DRIVER -
unless ENV['headless'].nil?
  require 'capybara/poltergeist'
  Capybara.register_driver :poltergeist do |app|
    options = {
        :window_size => [1280, 1024],
        :js_errors => true,
        :timeout => 120,
        :debug => false,
        :phantomjs_options => ['--load-images=no', '--disk-cache=false'],
        :inspector => true
    }
    Capybara::Poltergeist::Driver.new(app, options)
  end
  Capybara.default_driver    = :poltergeist
  Capybara.current_driver    = :poltergeist
  Capybara.javascript_driver = :poltergeist
else
  Capybara.register_driver :selenium_chrome do |app|
    Capybara::Selenium::Driver.new(app, :browser => :chrome)
  end
  Capybara.register_driver :selenium_firefox do |app|
    Capybara::Selenium::Driver.new(app, :browser => :firefox)
  end
  Capybara.register_driver :selenium_chrome_grid do |app|
    Capybara::Selenium::Driver.new(app, :browser => :remote, :url => "http://localhost:4444/wd/hub", :desired_capabilities => :chrome)
  end
  Capybara.register_driver :selenium_firefox_grid do |app|
    Capybara::Selenium::Driver.new(app, :browser => :remote, :url => "http://localhost:4444/wd/hub", :desired_capabilities => :firefox)
  end
  if ENV['browser'].nil?
    Capybara.default_driver = :selenium
    Capybara.current_driver = :selenium
  else
    Capybara.default_driver = "selenium_#{ENV['browser']}".to_sym
    Capybara.current_driver = "selenium_#{ENV['browser']}".to_sym
  end
end

# - DOMAIN -
domain = 'co.uk'
domain = ENV['domain'] unless ENV['domain'].nil?
raise 'Domain format is most likely not valid!' unless domain =~ /^[a-z]{2,3}\.[a-z]{2,3}|[a-z]{2,3}$/
Capybara.app_host = "http://www.amazon.#{domain}"

puts "Initialized..."