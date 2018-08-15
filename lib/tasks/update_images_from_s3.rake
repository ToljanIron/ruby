require './app/helpers/jobs_helper.rb'
require './app/helpers/cds_util_helper.rb'
include JobsHelper
include CdsUtilHelper

Dotenv.load if Rails.env.development? || Rails.env.onpremise?
s3_access_key = ENV['s3_access_key']
s3_secret_access_key = ENV['s3_secret_access_key']
s3_bucket_name = ENV['s3_bucket_name']
s3_region = ENV['s3_region']

TIMEOUT = 60 * 60 * 24

namespace :db do
  desc 'update_images_from_s3'
  task :update_images_from_s3, [:cid] => :setup_logger  do |t, args|
    cid = args[:cid] || -1
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    CdsUtilHelper.cache_delete_all

    puts "Task started"

    Aws.config.update({
      region: s3_region,
      credentials: Aws::Credentials.new(s3_access_key, s3_secret_access_key)
    })
    signer = Aws::S3::Presigner.new
    s3 =     Aws::S3::Resource.new
    bucket = s3.bucket(s3_bucket_name)

    puts "S3 objects created"

    ActiveRecord::Base.transaction do
      begin
        companies = (cid == -1 ? Company.all : Company.where(id: cid))
        companies.each do |company|
          cid = company.id

          ## Do by emails
          emails = Employee.select(:email).where("company_id = ?", cid).distinct.pluck(:email)

          emails.each do |email|
            puts "Working on employee: #{email}"
            emp_records = Employee.where(email: email)
            puts "    found: #{emp_records.length} emp_records"
            url = create_s3_object_url(cid, email, signer, bucket, s3_bucket_name)
            puts "    URL: #{url}"
            emp_records.update_all(img_url: url)
            emp_records.update_all(img_url_last_updated: Time.now)
          end

          ## Do by phone numbers
          phones = Employee.select(:phone_number).where("company_id = ?", cid).distinct.pluck(:phone_number)

          phones.each do |phone|
            puts "Working on employee with phone number: : #{phone}"
            emp_records = Employee.where(phone_number: phone)
            puts "    found: #{emp_records.length} emp_records"
            url = create_s3_object_url(cid, phone, signer, bucket, s3_bucket_name)
            puts "    URL: #{url}"
            if !url.nil?
              emp_records.update_all(img_url: url)
              emp_records.update_all(img_url_last_updated: Time.now)
            end
          end

        end unless companies.empty?
      rescue => e
        puts "***************"
        puts e.message
        puts e.backtrace
        raise ActiveRecord::Rollback
      end
    end
  end

  def create_s3_object_url(cid, ident, signer, bucket, bucket_name)
    url = create_url(cid, ident, 'jpg')
    puts "url: #{url}"
    url = bucket.object(url).exists? ? url : create_url(cid, ident, 'png')

    if bucket.object(url).exists?
      safe_url = signer.presigned_url(
                   :get_object,
                   bucket: bucket_name,
                   key: url,
                   expires_in: TIMEOUT)
      return safe_url
    else
      return nil
    end
  end

  def create_url(cid, email, image_type)
    return "employees/cid-#{cid}/#{email}.#{image_type}"
  end
end
