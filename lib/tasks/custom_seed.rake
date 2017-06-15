namespace :db do
  namespace :seed do
    Dir[File.join(Rails.root, 'db', 'seeds', '*.rb')].each do |filename|
      task_name = File.basename(filename, '.rb').to_sym
      task task_name => :environment do
        ActiveRecord::Base.transaction do
          begin
            puts "Seeding from #{task_name}".yellow unless Rails.env == 'test'
            load(filename) if File.exist?(filename)
          rescue => e
            puts "Seeding from #{task_name} failed".red unless Rails.env == 'test'
            puts e
            raise ActiveRecord::Rollback
          end
        end
      end
    end
  end
end
