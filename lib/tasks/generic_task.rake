require 'csv'
require 'zip'
require 'json'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    extids = Employee.select(:external_id).distinct.pluck(:external_id)
    ii = 0

    extids.each do |extid|
      ii += 1
      puts "Emp #{ii} of #{extids.length} "
      puts "===================================="
      Employee.where(external_id: extid).update_all(
        email: "#{SecureRandom.hex[0..12]}@bog.ge"
      )
    end

    puts "Done"

  end

  def safe_titleize(str)
    return nil if str.nil?
    str = str.to_s
    return str.titleize if !str.match(/^[a-zA-Z \-]*$/).nil?
    return str
  end
end
