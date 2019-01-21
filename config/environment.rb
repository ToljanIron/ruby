# Load the Rails application.
require File.expand_path('../application', __FILE__)

# set ENV['e2e_test'] != nil for e2e tests. this will affect RawDataEntries processing & snapshot creation process.
# look at create_snapshot_helper.rb for more details.
# ENV['e2e_test'] = 'true' unless Rails.env.test?

# Initialize the Rails application.
Workships::Application.initialize!

Dotenv.load

ActionMailer::Base.smtp_settings = {
  :address        => ENV['MAILGUN_ADDRESS'],
  :port           => ENV['MAILGUN_PORT'],
  :user_name      => ENV['MAILGUN_USER_NAME'],
  :password       => ENV['MAILGUN_PASSWORD'],
  :domain         => ENV['MAILGUN_DOMAIN'],
  :authentication => :plain, # or :plain for plain-text authentication
  :enable_starttls_auto => true, # or false for unencrypted connection
}

require 'rails_extensions'
