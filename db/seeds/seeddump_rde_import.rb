N =500
values = ''
ii = 1

line = nil

  File.open('/home/dev/Development/workships/db/seeds/xae').each do |l|
    begin
      if (ii % N == 0)
        puts "Wroking on record: #{ii}"
        values = values[0..-2]
        sqlstr = "INSERT INTO raw_data_entries (company_id, msg_id, \"from\", \"to\", cc, bcc, date, fwd, processed, priority, subject) VALUES #{values}"
        ActiveRecord::Base.transaction do
          begin
            ActiveRecord::Base.connection.execute(sqlstr)
          rescue
            raise ActiveRecord::Rollback
          end
        end
        values = ''
      end
      ii += 1
      line = l[0..-3]
      next if /.*\{[A-Z0-9]+\}.*/.match(line)
      h = JSON.parse(line, symbolize_keys: true)
      values += "(1, '#{h['msg_id']}', '#{h['from']}', '#{h['to']}', '#{h['cc']}', '#{h['bcc']}', '#{h['date']}', #{h['fwd']},false, 0, '#{h['subject']}'),"
    rescue => e
      puts "ERROR: #{e.message[0..500]}, arround line number #{ii}, with record: #{line}"
      puts e.backtrace[0..500]
      ii += 1
      values = ''
    end

  end

