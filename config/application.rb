require File.expand_path('../boot', __FILE__)

require 'rails/all'
require './lib/ext/float.rb'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Workships
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Jerusalem'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    #config.i18n.default_locale = :en
    I18n.enforce_available_locales = false

    # when queue_adapter is unset, jobs will run immediately
    # config.active_job.queue_adapter = :delayed_job
    config.active_job.queue_adapter = :sidekiq
    Dotenv.overload #if Rails.env.development?
    config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :forbidden
  end
end
