require 'csv'

namespace :db do
  desc 'SA database dump tool'
  task :sadump, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)


    import_to_model('./rawdataentry_dump_0.csv', 'raw_data_entries')
    import_to_model('./rawdataentry_dump_1.csv', 'raw_data_entries')
    import_to_model('./rawdataentry_dump_2.csv', 'raw_data_entries')

    #import_to_model('./company_dump.csv', 'companies')
    #import_to_model('./office_dump.csv', 'offices')
    #import_to_model('./jobtitle_dump.csv', 'job_titles')
    #import_to_model('./role_dump.csv', 'roles')
    #import_to_model('./group_dump.csv', 'groups')
    #import_to_model('./employee_dump.csv', 'employees')

    #dump_big_model(RawDataEntry, "date > '2017-01-01'", 500000)
    #dump_model(Snapshot)
    #dump_model(Company)
    #dump_model(Employee)
    #dump_model(Group)
    #dump_model(Role)
    #dump_model(Office)
    #dump_model(JobTitle)
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
        val = field[1]
        if val.class == String
          val = val.gsub('"', '')
          val = val.gsub(',', '')
          val = val.gsub("'", '')
          val = "\"#{val}\""
        end

        if val.class == ActiveSupport::TimeWithZone
          val = "\"#{val}\""
        end

        if val.class == NilClass
          val = "null"
        end
        row += "#{val},"
      end
      row[-1] = "\n"
      dump += row
    end

    file.write(dump)
  end

  def dump_big_model(model, cond='1=1', block_size=500000, write_block_size=2000)
    model_name = model.to_s.downcase

    num_of_blocks = model.where(cond).count / block_size

    (0..num_of_blocks).each do |ii|
      file_name = "./#{model_name}_dump_#{ii}.csv"
      puts "Working on: #{file_name}"
      file = File.open(file_name,'w')

      res = model.where(cond).offset(ii * block_size).limit(block_size)

      dump = ''
      if ii == 0
        heading = ''
        res.first.attributes.each do |field|
          heading += "#{field[0]},"
        end
        heading[-1] = "\n"
        dump = heading
      end

      jj = 1
      res.each do |r|
        row = ''
        r.attributes.each do |field|
          val = field[1]
	  if val.class == String
	    val.gsub!('"', '')
	    val.gsub!(',', '')
	    val = "\"#{field[1]}\""
	  end
	  row += "#{val},"
        end
        row[-1] = "\n"
        dump += row

        if ((jj % write_block_size) == 0)
          puts "Writing block number: #{jj}"
          file.write(dump)
          dump = ''
        end
        jj += 1
      end

      file.write(dump)
      file.close
    end
  end

  def import_to_model(file_name, table_name)
    file = File.open(file_name).read
    ii = 0
    prefix = ''
    sqlstr = ''

    file.each_line do |l|
      next if l.nil?
      len = l.length
      next if (len > 500 || len == 0 )

      begin

        prefix = create_prefix(table_name, l) if (ii == 0)
        sqlstr = prefix if (sqlstr.length == 0)
        line = l.strip
        line = line.gsub('"',"'")
        sqlstr += "(#{line})," if (ii > 0)
        ii += 1
        if ((ii % 100) == 0)
          puts "writing block number: #{ii}"
          sqlstr = "#{sqlstr[0..-2]}"
          ActiveRecord::Base.connection.exec_query(sqlstr)
          sqlstr = ''
        end

      rescue => e
        error = e.message[0..3000]
        puts "got exception: #{error}"
        puts e.backtrace
        sqlstr = ''
      end
    end

    puts "Writing last block"
    sqlstr = "#{sqlstr[0..-2]}"
    ActiveRecord::Base.connection.exec_query(sqlstr)
  end

  def create_prefix(table_name, heading)
    heading = heading.gsub('from', "\"from\"")
    heading = heading.gsub(',to,', ",\"to\",")
    return "insert into #{table_name} (#{heading.strip}) values "
  end
end
