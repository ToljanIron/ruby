namespace :db do
  desc 'simulate_employees_friendships'
  task simulate_employees_friendships: :environment do

    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    error = nil
    ActiveRecord::Base.transaction do
      begin
        employee_ids = Employee.select(:id)
        c = 0
        employee_ids.each do |i|
          employee_ids.each do |j|
            next if i == j
            Friendship.create(employee_id: i, friend_id: j, friend_flag: rand(2))
            c += 1
          end
        end
      rescue ActiveRecord::Rollback
        puts "simulate_employees_friendships ERROR: Failed with error: #{error}"
      end
    end
  end
end
