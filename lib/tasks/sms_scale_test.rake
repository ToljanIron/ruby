require 'twilio-ruby'

Dotenv.load if Rails.env.development? || Rails.env.onpremise?
PHONE       = ENV['TWILIO_FROM_PHONE']
account_sid = ENV['TWILIO_ACCOUNT_SID']
auth_token  = ENV['TWILIO_AUTH_TOKEN']
DEBUG = true.freeze
LIMIT = 2

namespace :db do
  desc 'sms_scale_test'
  task :sms_scale_test, [:qid] => :environment do |t, args|
    puts 'Running scale test'
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    begin

      idnums = Employee.where(company_id: 13).limit(LIMIT).pluck(:id_number)
      client = Twilio::REST::Client.new account_sid, auth_token

      idnums.each do |id|
        client.account.messages.create(
          from: PHONE,
          to:   PHONE,
          body: id.to_s
        ) if !DEBUG
        puts "SMS sent for ID: #{id}"
      end

    rescue => e
      puts 'got exception:', e.message, e.backtrace
    end
  end
end
