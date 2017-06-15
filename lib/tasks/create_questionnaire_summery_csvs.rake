require 'csv'
namespace :db do
  desc 'create_questionnaire_summery_csvs'
  task :create_questionnaire_summery_csvs, [:company_id] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.transaction do
      begin
        emps = Company.find(args[:company_id].to_i).active_employees.order(:id)
        friends_csv =  CSV.open('friends.csv', 'w')
        trust_csv = CSV.open('trust.csv', 'w')
        advice_csv = CSV.open('advice.csv', 'w')

        friends_csv << (1..20).map { |i| "friend_#{i}" }.unshift('employee')
        trust_csv << (1..20).map { |i| "trusted_#{i}" }.unshift('employee')
        advice_csv << (1..20).map { |i| "advisior_#{i}" }.unshift('employee')
        emps.each do|e|
          friends_names = Employee.find(e.friends).map { |x| x.email }.sort
          trusted_names = Employee.find(e.trusted).map { |x| x.email }.sort
          advisors_names = Employee.find(e.advisors).map { |x| x.email }.sort
          friends_names.unshift(e.email)
          trusted_names.unshift(e.email)
          advisors_names.unshift(e.email)
          friends_csv << friends_names
          trust_csv << trusted_names
          advice_csv << advisors_names
        end
      rescue => e
        puts 'got exception:', e.message, e.backtrace
        raise ActiveRecord::Rollback
      ensure
        friends_csv.close unless friends_csv.nil?
        trust_csv.close unless trust_csv.nil?
        advice_csv.close unless advice_csv.nil?
      end
    end
  end
end
