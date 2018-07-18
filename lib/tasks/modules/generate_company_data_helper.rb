module GenerateCompanyDataHelper
  require 'date'
  require './lib/tasks/modules/create_snapshot_helper.rb'
  include CreateSnapshotHelper

  MONTHLY = 1

  def build_pins(num_of_company)
    1..num_of_company.each do |i|
      if Employee.where(company_id: i).nil?
        fail 'no employees, so pin cant be created'
      end
      k = rand(Employee.where(company_id: i).size) / 2 + 1
      emp_selection_size = (k > 6) ? 6 : k
      pin_emps_emails = escape_quotes_in_arr(draw_k_employees_for_pin(i, emp_selection_size))
      definition = "{\"conditions\": [{\"param\": \"gender\", \"vals\": [1], \"oper\": \"notin\"}], \"employees\": #{pin_emps_emails}}"
      name = "company#{i}PIN1"
      Pin.create(company_id: i, name: name, definition: definition)
      k = rand(Employee.where(company_id: i).size) / 2 + 1
      emp_selection_size = (k > 6) ? 6 : k
      pin_emps_emails = escape_quotes_in_arr(draw_k_employees_for_pin(i, emp_selection_size))
      definition = "{\"conditions\": [{\"param\": \"gender\", \"vals\": [0], \"oper\": \"notin\"}], \"employees\": #{pin_emps_emails}}"
      name = "company#{i}PIN2"
      Pin.create(company_id: i, name: name, definition: definition)
      k = rand(Employee.where(company_id: i).size) / 2 + 1
      emp_selection_size = (k > 6) ? 6 : k
      pin_emps_emails = escape_quotes_in_arr(draw_k_employees_for_pin(i, emp_selection_size))
      definition = "{\"conditions\": [{\"param\": \"gender\", \"vals\": [0], \"oper\": \"in\"}], \"employees\": #{pin_emps_emails}}"
      name = "company#{i}PIN3"
      Pin.create(company_id: i, name: name, definition: definition)
      pins = Pin.where('company_id = ?', i)
      pins.each do |pin|
        emps = get_employees(pin, i)
        unless save_employees_to_pin(pin, emps)
          puts 'Error in update of employees in pin'
          fail 'can\'t create pin'
        end
      end
    end
  end

  def build_groups(company_id)
    a = Group.create!(company_id: company_id, name: "group#{company_id} aa", color_id: 1)
    b = Group.create!(company_id: company_id, name: "group#{company_id} bb", parent_group_id: a.id, color_id: 2)
    Group.create!(company_id: company_id, name: "group#{company_id} cc", parent_group_id: b.id, color_id: 3)
  end

  def create_employees(company_id, num_of_emps)
    unique_id = rand(100)
    1..num_of_emps.each do |emp|
      gender_size, marital_size = Employee.genders.size, MaritalStatus.all.size
      Employee.create!(company_id: company_id,
                       email: "e#{emp}@mailcomp#{company_id}.com",
                       first_name: "John#{company_id}-#{emp}",
                       last_name: "Doe#{company_id}-#{emp}",
                       external_id: unique_id,
                       group_id: (unique_id % Group.all.size) + 1 + (company_id - 1) * Group.all.size,
                       gender: rand(gender_size),
                       marital_status_id: rand(marital_size) + 1,
                       color_id: rand(12) + 1,
                       rank_id: rand(12) + 1)
      unique_id += 1
    end
  end

  def drop_all_tables
    conn = ActiveRecord::Base.connection
    postgres = "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname='public'"
    tables = conn.execute(postgres).map { |r| r['tablename'] }
    tables -= ['schema_migrations']
    tables.each do |table|
      ActiveRecord::Base.connection.execute("DELETE FROM #{table} WHERE 1 = 1")
      ActiveRecord::Base.connection.reset_pk_sequence!(table)
    end
    puts 'DROPPED ALL TABLES'
  end

  def drop_noncsv_tables
    conn = ActiveRecord::Base.connection
    postgres = "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname='public'"
    tables = conn.execute(postgres).map { |r| r['tablename'] }
    tables -= %w(schema_migrations employees groups friendships friendships_snapshots advices advices_snapshots)
    tables.each do |table|
      ActiveRecord::Base.connection.execute("DELETE FROM #{table} WHERE 1 = 1")
      ActiveRecord::Base.connection.reset_pk_sequence!(table)
    end
    puts 'DROPPED ALL NON CSV TABLES'
  end

  # def create_advice(company_id, prob)
  #   Advice.delete_all
  #   emps = Employee.where('company_id = ?', company_id)
  #   fail 'no employees, Advice can\'t be created' if emps.nil?
  #   emps.pluck(:id).permutation(2).to_a.each do | comb|
  #     emp_id = comb[0]
  #     other_id = comb[1]
  #     flag = rand < prob ? 1 : 0
  #     Advice.create(employee_id: emp_id, advicee_id: other_id, advice_flag: flag)
  #   end
  # end

  def create_advice_snapshot(company_id, prob)
    emps = Employee.where('company_id = ?', company_id)
    fail 'no employees, Advice Snapshots can\'t be created' if emps.nil?
    if Snapshot.where('company_id = ?', company_id).nil?
      fail "no Snapshots, advices_snapshot can't be created"
    end
    Snapshot.where(company_id: company_id).each do |i|
      emps.pluck(:id).permutation(2).to_a.each do | comb|
        emp_id = comb[0]
        other_id = comb[1]
        flag = rand < prob ? 1 : 0
        AdvicesSnapshot.create(employee_id: emp_id, advicee_id: other_id, advice_flag: flag, snapshot_id: i.id)
      end
    end
  end

  # def create_friendship(company_id, prob)
  #   Friendship.delete_all
  #   emps = Employee.where('company_id = ?', company_id)
  #   fail 'no employees, friendship can\'t be created' if emps.nil?
  #   emps.pluck(:id).permutation(2).to_a.each do | comb|
  #     emp_id = comb[0]
  #     other_id = comb[1]
  #     flag = rand < prob ? 1 : 0
  #     emp = Employee.where(id: emp_id)
  #     friend = Employee.where(id: other_id)
  #     Friendship.create!(employee_id: emp.first, friend_id: friend.first, friend_flag: flag)
  #   end
  # end

  def create_friendship_snapshot(company_id, prob)
    emps = Employee.where('company_id = ?', company_id)
    fail 'no employees, friendship_snapshot can\'t be created' if emps.nil?
    fail 'no employees, friendship_snapshot can\'t be created' if Snapshot.where('company_id = ?', company_id).nil?
    Snapshot.where(company_id: company_id).each do |i|
      emps.pluck(:id).permutation(2).to_a.each do |comb|
        emp_id = comb[0]
        other_id = comb[1]
        flag = rand < prob ? 1 : 0
        FriendshipsSnapshot.create!(employee_id: emp_id, friend_id: other_id, friend_flag: flag, snapshot_id: i.id)
      end
    end
  end

  def create_snapshots(company_id, num_snapshots, raw_data_num, flag_prob)
    (1..num_snapshots).each do |i|
      date = (Time.now.to_date - (num_snapshots - i).month).strftime('%Y-%m-22')
      create_raw_data_wrapper(company_id, raw_data_num, date)
      create_advice_snapshot(company_id, flag_prob)
      create_friendship_snapshot(company_id, flag_prob)
      create_company_snapshot(company_id, date, MONTHLY, true)
    end
  end

  def create_raw_data_wrapper(company_id, num_mails_sent, date)
    employees = Employee.where('company_id = ?', company_id)
    fail 'No employees in company. Can\'t create emails' if employees.nil?
    employees.each do |emp|
      create_raw_data(company_id, emp.id, num_mails_sent, date)
    end
  end

  def create_raw_data(company_id, employee_id, num_mails_sent, date)
    employee_id_bank = Employee.where('id != ? AND company_id = ?', employee_id, company_id).pluck(:id)
    fail 'employee size too small' if Employee.size == 0 || Employee.size == 1 || employee_id_bank.size == 0
    from_email = Employee.where(id: employee_id).first.email || 'some_default@email.com'
    (1..num_mails_sent).each do
      fwd = rand(2)
      to_id = employee_id_bank.sample
      to = Employee.where(id: to_id).first.email.split
      if Employee.size < 4
        cc = bcc = from_email.split
      else
        cc  = Employee.where(id: employee_id_bank.sample).first.email.split
        bcc = Employee.where(id: employee_id_bank.sample).first.email.split
      end
      RawDataEntry.create!(company_id: company_id, from: from_email, 'to' => to, 'cc' => cc, 'bcc' => bcc, fwd: fwd, msg_id: 'message', date: date)
    end
  end

  def draw_k_employees_for_pin(company_id, k)
    res = []
    emps = Employee.where('company_id = ?', company_id)
    emps.each do |emp|
      res << emp.email
    end
    res = res.sample(k)
    return res
  end

  def create_users
    User.create!(name: 'guy', email: 'guy@spectory.com', password: 'qwe123qwe', password_confirmation: 'qwe123qwe')
    User.create!(name: 'raz', email: 'raz@spectory.com', password: '123123', password_confirmation: '123123')
    User.create!(name: 'danny', email: 'danny@spectory.com', password: 'qwe123', password_confirmation: 'qwe123')
    User.create!(name: 'zvi', email: 'zvi@spectory.com', password: '11White!', password_confirmation: '11White!')
    User.create!(name: 'yael', email: 'yael@spectory.com', password: '123123', password_confirmation: '123123')
    User.create!(name: 'avi', email: 'avi@dualia.co.il', password: 'aviD121!', password_confirmation: 'aviD121!')
    User.create!(name: 'idit', email: 'idit@dualia.co.il', password: 'iditD121!', password_confirmation: 'iditD121!')
    User.create!(name: 'itai', email: 'itai@spectory.com', password: 'itai121!', password_confirmation: 'itai121!')
    User.create!(name: 'sharon', email: 'sharon@gome.co.il', password: 'sharon121!', password_confirmation: 'sharon121!')
  end

  def escape_quotes_in_arr(arr)
    arr.each do |a|
      a = a.inspect
    end
  end

  def validate_arguments(mode, num_of_comps, num_of_emps, num_of_sshots, raw_data, prob)
    mode = 1 if mode != 1 && mode != 2
    num_of_comps = 1 if num_of_comps <= 0
    num_of_emps = 2 if num_of_emps <= 1
    num_of_sshots = 1 if num_of_sshots <= 0
    raw_data = 1 if raw_data <= 0
    prob = 0.5 if prob <= 0 || prob > 1
    return { mode: mode, num_of_comps: num_of_comps, num_of_emps: num_of_emps, num_of_sshots: num_of_sshots, raw_data: raw_data, prob: prob }
  end

  def get_name(date, snapshot_type)
    ret = ''
    # puts date
    case snapshot_type
    when TYPE_WEEK
      ret = "Weekly-#{date}"
    when TYPE_MONTH
      ret = "Monthly-#{date.year}-#{date.month}"
    when TYPE_YEAR
      ret = "Yearly-#{date.year}"
    else
      fail "Illegal snapshot_type: #{snapshot_type}"
    end
    puts "ret#{ret}"
    return ret
  end
end
