require 'csv'
require 'zip'
require 'json'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    empids = Employee.where(snapshot_id: 149).pluck(:id)

    ii = 0
    empids.each do |fid|
      puts "working on emp number #{ii}"
      sqlstr = "insert into network_snapshot_data (snapshot_id, network_id, company_id, from_employee_id, to_employee_id, value) values "
      empids.each do |tid|
        next if fid == tid
        sqlstr = "#{sqlstr} (149, 108, 11, #{fid}, #{tid}, 1)," if (rand(100) < 10)
      end
      ii += 1
      sqlstr = sqlstr[0..-2]
      ActiveRecord::Base.connection.execute( sqlstr )
    end

    puts "Done"

  end

end
