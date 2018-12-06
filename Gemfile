source 'https://rubygems.org'

ruby '2.4.4'
gem 'rails', '5.2.1'
#gem 'clockwork'
gem 'pundit'
gem 'bcrypt'
gem 'pg', '~> 0.18'
gem 'descriptive-statistics'
gem 'writeexcel'
gem 'fastimage'
gem 'oj'
gem 'oj_mimic_json'
gem 'backup', '3.4.0'
gem 'activerecord'
#gem 'tiny_tds'
#gem 'activerecord-sqlserver-adapter', '>= 4.2.0'
gem 'dotenv'
gem 'meta_request'
gem 'literate_randomizer', '~> 0.4.0'
gem 'delayed_job_active_record'
gem 'hirb'
gem 'rack-cors'
gem 'jwt'
gem 'thor', '0.19.1'
gem 'nmatrix'
gem 'tzinfo-data'
gem 'awesome_print'
gem 'byebug'


group :production, :onpremise, :development do
  gem 'mail'
  gem 'write_xlsx'
  gem 'net-sftp'
  gem 'roo'
  gem 'roo-xls', '~>1.1.0'
  gem 'dalli'
  gem 'therubyracer'
  gem 'sass-rails', '~> 5.0'
  gem 'compass-rails', '3.0.2'
  gem 'uglifier'
  gem 'ejs'
  gem 'yui-compressor'
  gem 'sprockets'
  gem 'sprockets-rails','>= 3.0.0'
  gem 'font-awesome-rails'
  gem 'twilio-ruby'
  gem "jqcloud-rails"
  gem "daemons"
  gem 'colorize'
end

group :development, :test do
  gem 'rspec-rails', '~> 3.8'
  gem 'guard-rspec'
  gem 'spork'
  gem 'guard-spork'
  gem 'jasmine-rails'
  gem 'guard-shell'
  gem 'simplecov', require: false, group: :test
  gem 'guard-rubocop'
  gem 'scss_lint'
  gem 'transpec'
  gem 'database_cleaner'
  gem 'seed_dump'
end

group :test do
  #gem 'faker'
  #gem 'ruby-prof'
  #gem 'capybara'
  #gem 'libnotify'
  gem 'factory_bot', '~> 4.11', '>= 4.11.1'
  #gem 'rubocop-rspec'
end

group :production do
  gem 'aws-sdk', '~> 3.0.0.rc1'
  gem 'heroku-deflater'
end

group :production, :onpremise do
  gem 'passenger', '5.3.4'
  gem 'rails_12factor', '0.0.2'
end
