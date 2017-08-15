require 'csv'

namespace :db do
  desc 'SA database dump tool'
  task :sadump, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)


    dump_model(Employee)
    dump_model(Group)
    dump_model(Role)
    dump_model(Office)
    dump_model(JobTitle)
    puts "Done"

  end

  def dump_model(model)
    model_name = model.to_s.downcase
    file_name = "./#{model_name}_dump.csv"

    puts "Working on: #{file_name}"

    file = File.open(file_name,'w')

    res = model.all

    heading = ''
    res.first.attributes.each do |field|
      heading += "#{field[0]},"
    end
    heading[-1] = "\n"
    dump = heading

    res.each do |r|
      row = ''
      r.attributes.each do |field|
        row += "#{field[1]},"
      end
      row[-1] = "\n"
      dump += row
    end

    file.write(dump)

  end
end
