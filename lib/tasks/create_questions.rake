require './app/helpers/csv_loader.rb'
namespace :db do
  desc 'create_questions'
  task :create_questions, [:cid, :date, :type] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    cid   = args[:cid]  || ENV['COMPANY_ID'] || (fail 'No company ID given (cid)')
    puts "Running with CID=#{cid}"
    UtilHelper.cache_delete_all
    ActiveRecord::Base.transaction do
      begin
        @comp = Company.find(cid.to_i)
        CsvLoader.create_questions(@comp) if @comp

      rescue => e
        error = e.message
        puts "got exception: #{error}"
        puts e.backtrace
        raise ActiveRecord::Rollback
      end
    end
  end
end
