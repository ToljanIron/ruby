require 'simplecov'

if ENV['COVERAGE']
  SimpleCov.start 'rails' do
    Dir.glob('lib/tasks/*.rake').each do |task_file|
      add_filter task_file
    end
  end
end

require 'rubygems'
require 'spork'

Spork.prefork do

  ENV['RAILS_ENV'] ||= 'test'
  require File.expand_path('../../config/environment', __FILE__)
  require 'rspec/rails'
  Workships::Application.load_tasks

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

  # Checks for pending migrations before tests are run.
  # If you are not using ActiveRecord, you can remove this line.
  ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

  RSpec::Expectations.configuration.warn_about_potential_false_positives = false

  RSpec.configure do |config|
    config.filter_run_excluding performance: true unless ENV['PERFORMANCE']
    config.filter_run_excluding write_file: true unless ENV['WRITE_FILE']

    config.fixture_path = "#{::Rails.root}/spec/fixtures"
    config.use_transactional_fixtures = false  # <<< important!!
    config.infer_base_class_for_anonymous_controllers = false
    config.order = 'random'
    config.include Capybara::DSL

    config.before(:suite) do
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.clean_with(:truncation)
    end

    config.after(:suite) do
      DatabaseCleaner.clean_with(:truncation)
    end
  end

  Spork.each_run do
    # This code will be run each time you run your specs.
    #Dir['./spec/factories/*_factory.rb'].each { |ff| require ff }
  end
end

###########################################
# For running authenticated tests in rspec
###########################################
def log_in_with_dummy_user
  @user = User.create!(id: 1, role: 1, company_id: 1, first_name: 'name', email: 'user@company.com', password: 'qwe123', password_confirmation: 'qwe123')
  return @user
end

###############################################################
# For running authenticated get requests in controller tests
###############################################################
def http_get_with_jwt_token(action, p = {})
  request.headers.merge!({'Authorization': "Bearer #{ENV['JWT_TOKEN_FOR_TESTING']}"})
  ret = get(action, params: p)
  return ret
end

def http_post_with_jwt_token(action, p = {})
  request.headers.merge!({'Authorization': "Bearer #{ENV['JWT_TOKEN_FOR_TESTING']}"})
  ret = post(action, params: p)
  return ret
end

def pp(q)
  puts "$$$$$$$$$$$$$$$$$$$$$$$$"
  ap q
  puts "$$$$$$$$$$$$$$$$$$$$$$$$"
end
