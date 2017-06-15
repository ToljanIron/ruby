namespace :db do
  desc 'update_images_url_on_premise'
  task update_images_url_on_premise: :environment do
    expiration = 1.minute.ago
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.transaction do
      begin
        emp_list = Employee.all
        emp_list.each do |emp|
          img_url = '/employees/' +  emp.email + '.jpg'
          emp.update_attribute(:img_url, img_url)
        end
      rescue => e
        puts 'got exception:', e.message, e.backtrace
        raise ActiveRecord::Rollback
      end
    end
  end
end
