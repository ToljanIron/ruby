require 'csv'
require 'zip'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)


    Zip::File.open('./qqq.zip') do |archive|
      archive.each do |entry|
        puts entry.extract("./#{entry.to_s}")
      end
    end

    puts "Done"

  end
end
