source 'https://rubygems.org'

ruby '3.2.2'
gem 'rails', '~> 6.1'
#gem 'clockwork'
gem 'pundit'
gem 'bcrypt'
gem 'pg',  '~> 1.5', '>= 1.5.4'
gem 'descriptive-statistics'
gem 'writeexcel'
gem 'fastimage'
gem 'oj'
gem 'oj_mimic_json'
gem 'backup', '3.4.0'
gem 'activerecord'
#gem 'tiny_tds'
#gem 'activerecord-sqlserver-adapter'
gem 'dotenv'
gem 'meta_request'
gem 'literate_randomizer', '~> 0.4.0'
gem 'delayed_job_active_record'
gem 'hirb'
gem 'rack-cors'
gem 'jwt'
gem 'thor'
gem 'nmatrix', git: 'https://github.com/tree-tech-il/nmatrix.git', branch: 'ruby_3_2_compatibility'
gem 'tzinfo-data'
gem 'awesome_print'
gem 'byebug'
gem 'sidekiq', '5.2.9'
gem 'redis'

group :production, :onpremise, :development do
  gem 'mail'
  gem 'write_xlsx'
  gem 'net-sftp'
  gem 'nokogiri'
  gem 'roo'
  gem 'roo-xls', '~>1.1.0'
  gem 'dalli'
  #gem 'therubyracer'
  gem 'mini_racer'
  gem 'sassc-rails'
  gem 'uglifier'
  gem 'ejs'
  #gem 'yui-compressor'
  gem 'sprockets'
  gem 'sprockets-rails'
  gem 'font-awesome-rails'
  gem 'twilio-ruby' ,'5.4.5'
  gem "jqcloud-rails"
  gem "daemons"
  gem 'colorize'
  gem 'aws-sdk', '~> 3.0.0.rc1'
end

group :development, :test do
  gem 'spork'
  gem 'rspec'
  gem 'rspec-core'  
  gem 'rspec-rails', '~> 6.0', '>= 6.0.3'  # gem 'transpec'
  gem 'seed_dump'
  gem 'puma', '~> 3.7'
  #gem 'solargraph'
  
end

group :test do
  gem 'factory_bot'
  gem 'database_cleaner'
  gem 'jasmine-rails'
  gem 'simplecov'
end

group :production do
  gem 'heroku-deflater'
end

group :production, :onpremise do
  gem 'passenger', '5.3.4'
  gem 'rails_12factor', '0.0.2'
end

#post rails 6 upgrade
gem 'net-ftp'
