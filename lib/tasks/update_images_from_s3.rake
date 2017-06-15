require './app/helpers/jobs_helper.rb'
require './app/helpers/util_helper.rb'
include JobsHelper
include UtilHelper

namespace :db do
  desc 'update_images_from_s3'
  task update_images_from_s3: :environment do
    expiration = 1.second.ago
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    UtilHelper.cache_delete_all
    t_id = ENV['ID'].to_i
    ActiveRecord::Base.transaction do
      begin
        start_job(t_id) if t_id != 0
        companies = Company.all
        companies.each do |company|
          expired_emp = Employee.where('img_url_last_updated < ? and company_id = ?', expiration, company.id)
          expired_emp.each do |emp|
            emp.img_url = emp.check_img_url
            emp.img_url_last_updated = Time.now
            emp.save!
          end
        end unless companies.empty?
        finish_job(t_id) if t_id != 0
      rescue => e
        puts e.message
        puts e.backtrace
        finish_job_with_error(t_id) if t_id != 0
        raise ActiveRecord::Rollback
      end
    end
  end
end
