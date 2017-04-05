source 'http://rubygems.org'

gem 'whoops_rails_logger', :git=> 'https://github.com/IntersectAustralia/whoops_rails_logger.git'

gem 'rails', '5.0.2'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

#gem 'pg'
gem 'mysql2'
# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass', '~> 3.4.23'
  gem 'sass-rails',   '~> 5.0.6'
  gem 'coffee-rails', '~> 4.2.1'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :test do
  # Pretty printed test output
  gem 'turn', '~> 0.8.3', :require => false
end

gem "therubyracer"
group :development, :test do
  gem "create_deployment_record", git: 'https://github.com/IntersectAustralia/create_deployment_record.git'
  gem "rspec-rails"
  gem "factory_girl_rails"
  gem "shoulda-matchers", '2.8'
  gem 'xray-rails'
  gem 'pry-rails'

  # cucumber gems
  gem "cucumber"
  gem "capybara"
  gem "database_cleaner"
  gem "spork", '~> 0.9.0.rc'
  gem "launchy"    # So you can do Then show me the page
  gem "minitest"  # currently breaks without this
  gem "minitest-reporters"
end

group :development do
  gem "rails3-generators"
  gem 'thin'
  gem 'cheat'

end

group :test do
  gem "cucumber-rails", require: false
end

#group :production do
  gem 'google-analytics-rails'
#end

gem "iconv"
gem "haml"
gem "haml-rails"
gem "tabs_on_rails"
gem "devise" , "4.2.0"
gem "email_spec", :group => :test
gem "cancancan"
gem "capistrano-ext"
gem "capistrano", '~> 3.7.2'
gem 'rvm-capistrano', require: false
gem "colorize"
gem "simplecov", :require => false, :group => :test
gem "simplecov-rcov", :require => false, :group => :test
gem "bootstrap-sass", '~> 3.3.7'
gem "paperclip", "~> 5.1.0"
gem 'delayed_job', '~> 4.1.2'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'prawn'
gem 'prawn-table'
gem 'decent_exposure'
gem 'will_paginate', '> 3.0'
gem 'will_paginate-bootstrap'
gem 'whenever', require: false

gem 'jekyll', :require => false

gem 'highline' # This has (up until now) been implicitly included by capistrano
gem 'passenger', '~> 5.1.2', :require => false
