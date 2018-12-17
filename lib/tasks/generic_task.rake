require 'csv'
require 'zip'
require 'json'
require 'twilio-ruby'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    # Get your Account SID and Auth Token from twilio.com/console
    account_sid = 'AC03d0412a54b3e287104ed1c8bf6cbc02'
    auth_token = '9bc9acef34899cd1b1ad85e16fd5690c'

    # Initialize Twilio Client
    @client = Twilio::REST::Client.new(account_sid, auth_token)

    # Get an object from its sid. If you do not have a sid,
    # check out the list resource examples on this page
    res = @client.messages.create(
      from: '+972524649837',
      to:   '+972052-6141030',
      body: 'Test123')

    puts "======================="
    ap res
    puts "======================="
  end
end

