require './lib/tasks/modules/generate_company_data_helper.rb'
include GenerateCompanyDataHelper

namespace :db do
  desc 'generate_company_data'
  task :generate_company_data, [:mode, :num_of_companies, :num_of_emps, :num_of_sshots, :raw_data_num, :flag_prob] => :environment do |t, args|

    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.transaction do
      begin
        #params = validate_arguments(args[:mode].to_i, args[:num_of_companies].to_i, args[:num_of_emps].to_i,args[:num_of_sshots].to_i, 
        #  args[:raw_data_num].to_i, args[:flag_prob].to_f)
        #mode, num_of_companies, num_of_emps, num_of_sshots, raw_data_num, flag_prob  = params[:mode] , params[:num_of_comps], params[:num_of_emps],
        #params[:num_of_sshots], params[:raw_data], params[:prob]
        mode = 1
        num_of_companies = 1
        num_of_emps = 10
        num_of_sshots = 9
        raw_data_num = 10
        flag_prob = 0.5
        if mode == 1
          drop_all_tables
        end
        if mode == 2
          drop_noncsv_tables
        end
        create_users
        for  i in 1..num_of_companies do
          Company.create(name: "company#{i}")
        end
        if mode == 1
          for  i in 1..num_of_companies do
            build_groups(i)
            create_employees(i, num_of_emps)
          end
        end
        build_pins(num_of_companies)
        for  i in 1..num_of_companies do
          create_snapshots(i, num_of_sshots, raw_data_num, flag_prob)
        end
      rescue => e
       error = e.message
       puts "got exception: #{error}"
       puts e.backtrace
       raise ActiveRecord::Rollback
     end
   end
 end
end
