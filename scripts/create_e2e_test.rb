#!/usr/bin/env ruby
on_heroku = !ARGV[0].nil?
prefix = ''
postfix = ''
valid_apps = %w(workships-zim)

if on_heroku
  unless valid_apps.include?(ARGV[0])
    puts "#{ARGV[0]} is invalid heroku app"
    exit
  end
  prefix = 'heroku run'
  postfix = "-a #{ARGV[0]}"
  puts "heroku pg:reset DATABASE #{postfix} --confirm #{ARGV[0]}"
  `heroku pg:reset DATABASE #{postfix} --confirm #{ARGV[0]}`
  puts "heroku run rake db:migrate #{postfix}"
  `heroku run rake db:migrate #{postfix}`
end

# seed tables
puts 'seeding...'
puts `#{prefix} rake db:seed:users #{postfix}`
puts `#{prefix} rake db:seed:event_types #{postfix}`
puts `#{prefix} rake db:seed:metrics #{postfix}`
puts `#{prefix} rake db:seed:marital_statuses #{postfix}`
puts `#{prefix} rake db:seed:colors #{postfix}`
puts `#{prefix} rake db:seed:age_group_and_seniority #{postfix}`
puts `#{prefix} rake db:seed:ranks #{postfix}`
puts `#{prefix} rake db:seed:reoccurrences #{postfix}`
puts `#{prefix} rake db:seed:api_clients_and_configs #{postfix}`
puts `#{prefix} rake db:seed:system_jobs #{postfix}`

# create company

puts `#{prefix} rake db:seed:test_company_seed name=exchage-company-50-emps size=50 type=exchange #{postfix}`

# schedule jobs & tasks
# rake db:schedule_jobs && rake db:create_scheduled_tasks
