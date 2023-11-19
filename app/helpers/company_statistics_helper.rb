module CompanyStatisticsHelper

  FRIENDSHIP = 1
  ADVICE = 2
  TRUST = 3
  NO_COMPANY = -1
  NO_SNAPSHOT = -1

  def self.calculate_company_statistics(cid = -1, sid = -1)
    puts "CompanyStatisticsHelper started calculating company statistics for #{Company.find(cid).name}"
    companies = cid == NO_COMPANY ? cds_find_companies(gid, pid, sid) : Company.where(id: cid)
    companies.each do |company|
      snapshots = sid == NO_SNAPSHOT ? Snapshot.where(company_id: company.id).order('timestamp DESC').limit(1) : Snapshot.where(id: sid, company_id: company.id)
      snapshots.each do |snapshot|
        CompanyStatistics.where(snapshot_id: snapshot.id).delete_all
        calculate_email_statistics(snapshot.id)
        calculate_questionnair_statistics(snapshot.id)
      end
    end
  end

  def self.calculate_email_statistics(sid)
    total_amount_of_workers_per_snapshot(sid)
    amount_of_emails_per_snapshot(sid)
    minimum_amount_of_emails_per_snapshot(sid)
    maximum_amount_of_emails_per_snapshot(sid)
    avg_amount_of_emails_per_snapshot(sid)
    total_emails_replied_per_snapshot(sid)
    total_emails_fwd_per_snapshot(sid)
    top_email_recipient_to_per_snapshot(sid)
    top_email_recipient_cc_per_snapshot(sid)
  end

  def self.calculate_questionnair_statistics(sid)
    num_of_questionnairs_per_snapshot(sid)
    num_of_answered_questionnairs_per_snapshot(sid)
    maximum_friends_per_snapshot(sid)
    avg_friends_per_snapshot(sid)
    minimum_friends_per_snapshot(sid)
    maximum_advice_per_snapshot(sid)
    avg_advice_per_snapshot(sid)
    minimum_advice_per_snapshot(sid)
  end

  def self.total_amount_of_workers_per_snapshot(sid)
    company = get_company(sid)
    title = 'No. of Employees'
    tooltip = 'The total number of monitored employees in the company'
    num_of_emps = Company.employees(company.id).where.not(email:'other@mail.com').count
    icon_path = '/assets/statistics_imgs/Number_Of_Employees.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: num_of_emps, icon_path: icon_path, link_to: '', display_order: 1)
  end

  def self.amount_of_emails_per_snapshot(sid)
    company = get_company(sid)
    title = 'Volume of Emails Analyzed'
    tooltip = 'The total amount of email messages, across the company, the system has analyzed this week'
    @amount_of_emails = calc_volume_of_emails(sid)
    icon_path = '/assets/statistics_imgs/Amount_Of_Emails_Analyzed.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: @amount_of_emails, icon_path: icon_path, link_to: 'Productivity', display_order: 1)
  end

  # def self.time_spent_on_emails_per_snapshot(sid)
  #   company = get_company(sid)
  #   title = 'Time Spent on Emails'
  #   tooltip = 'Time spent on emails (According to benchmark) in light of the total company'
  #   time_spent_on_emails = @amount_of_emails*60
  #   if 
  #   icon_path = '/assets/statistics_imgs/Amount_Of_Emails_Analyzed.png'
  #   CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: amount_of_emails, icon_path: icon_path, link_to: 'Productivity', display_order: 1)
  # end

  def self.minimum_amount_of_emails_per_snapshot(sid)
    company = get_company(sid)
    title = 'Min No. of Emails to Employee'
    tooltip = 'The amount of emails that were sent to the employee who received the least number of email messages, across the company, this week'
    minimum_emails_received = find_minimum_amount_of_emails_for_employee_per_snapshot(sid)
    icon_path = '/assets/statistics_imgs/Least_Amount_Of_Emails_Sent.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: minimum_emails_received, icon_path: icon_path, link_to: 'Productivity', display_order: 1)
  end

  def self.maximum_amount_of_emails_per_snapshot(sid)
    company = get_company(sid)
    title = 'Max No. of Emails to Employee'
    tooltip = 'The amount of emails that were sent to the employee who received the most number of email messages, across the company, this week'
    maximum_emails_received = find_maximum_amount_of_emails_for_employee_per_snapshot(sid)
    icon_path = '/assets/statistics_imgs/Max_Amount_Of_Emails_Sent.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: maximum_emails_received, icon_path: icon_path, link_to: 'Productivity', display_order: 1)
  end

  def self.avg_amount_of_emails_per_snapshot(sid)
    company = get_company(sid)
    title = 'Avg. No. of Emails to Employee'
    tooltip = 'The avarage number of emails that were sent per employee, across the company, this week'
    avg_emails_received = find_avg_amount_of_emails_for_employee_per_snapshot(sid)
    icon_path = '/assets/statistics_imgs/Average_Amount_Of_Emails_Sent.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: avg_emails_received, icon_path: icon_path, link_to: 'Productivity', display_order: 1)
  end

  def self.total_emails_replied_per_snapshot(sid)
    company = get_company(sid)
    title = 'Total Emails Replied'
    tooltip = 'The amount of replied email message, across the company, this week'
    total_email_replied = NetworkSnapshotData.where("(from_type = 2) AND snapshot_id = #{sid}").count
    icon_path = '/assets/statistics_imgs/Total_Emails_Replied.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: total_email_replied, icon_path: icon_path, link_to: 'Productivity', display_order: 1)
  end

  def self.total_emails_fwd_per_snapshot(sid)
    company = get_company(sid)
    title = 'Total Emails Forwarded'
    tooltip = 'The amount of forwarded email messages, across the company, this week'
    total_email_fwd = NetworkSnapshotData.where("(from_type = 3) AND snapshot_id = #{sid}").count
    icon_path = '/assets/statistics_imgs/Total_Forwarded_Emails.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: total_email_fwd, icon_path: icon_path, link_to: 'Productivity', display_order: 1)
  end

  def self.top_email_recipient_to_per_snapshot(sid)
    company = get_company(sid)
    title = 'Top Email Recipient - to'
    tooltip = 'The amount of emails that were sent to the employee who received the maximum number of email messages in which he/she were addressed as "TO" , across the company, this week'
    top_email_recipient = get_top_email_recipient_to(sid)
    icon_path = '/assets/statistics_imgs/Top-Email_Recipient_To.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: top_email_recipient, icon_path: icon_path, link_to: 'Productivity', display_order: 1)
  end

  def self.top_email_recipient_cc_per_snapshot(sid)
    company = get_company(sid)
    title = 'Top Email Recipient - cc'
    tooltip = 'The amount of emails that were sent to the employee who received the maximum number of email messages in which he/she were addressed as "CC" , across the company, this week'
    top_email_recipient = get_top_email_recipient_cc(sid)
    icon_path = '/assets/statistics_imgs/Top_Email_Recipient_Cc.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: top_email_recipient, icon_path: icon_path, link_to: 'Productivity', display_order: 1)
  end


  def self.get_top_email_recipient_to(sid)
    company = get_company(sid)
    max = nil
    emps = Employee.where(company_id: company.id)
    emps.each do |emp|
      emp_amount = NetworkSnapshotData.where("snapshot_id = #{sid} AND to_employee_id = #{emp.id} AND (to_type = 1)").count
      max = emp_amount if max.nil? || emp_amount > max
    end
    return max.to_i
  end

  def self.get_top_email_recipient_cc(sid)
    company = get_company(sid)
    max = nil
    emps = Employee.where(company_id: company.id)
    emps.each do |emp|
      emp_amount = NetworkSnapshotData.where("snapshot_id = #{sid} AND to_employee_id = #{emp.id} AND (to_type = 2)").count
      max = emp_amount if max.nil? || emp_amount > max
    end
    return max.to_i
  end

  def self.get_company(sid)
    return Company.find(Snapshot.find(sid).company_id)
  end

  def self.find_minimum_amount_of_emails_for_employee_per_snapshot(sid)
    company = get_company(sid)
    min_emp_email_amount = 0
    emps = Employee.where(company_id: company.id)
    emps.each do |emp|
      emp_email_amount = NetworkSnapshotData.where(snapshot_id: sid, to_employee_id: emp.id).count
      min_emp_email_amount = emp_email_amount unless min_emp_email_amount < emp_email_amount
    end
    return min_emp_email_amount
  end


  def self.num_of_questionnairs_per_snapshot(sid)
    company = get_company(sid)
    title = 'No. of Completed Questionnaires'
    tooltip = 'Total number of questionnaires the comapny has run using the system since installation and launch'
    num_of_questionnairs = Questionnaire.where(company_id: company.id).count
    icon_path = '/assets/statistics_imgs/Questionnaire.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: num_of_questionnairs, icon_path: icon_path, link_to: '', display_order: 1)
  end

  def self.num_of_answered_questionnairs_per_snapshot(sid)
    company = get_company(sid)
    title = 'No. of Respondents'
    tooltip = 'Total number of questionnaires the comapny has run using the system since installation and launch'
    num_of_questionnairs = get_num_of_respondents(sid, company.id)
    icon_path = '/assets/statistics_imgs/Questionnaires_Completed.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: num_of_questionnairs, icon_path: icon_path, link_to: '', display_order: 1)
  end

  def self.maximum_friends_per_snapshot(sid)
    company = get_company(sid)
    title = 'Max Friendliness Indications'
    tooltip = 'The amount of indications of an employee as a friend of the most indicated employee'
    num_of_friends = get_num_of_friends(sid, company.id)
    icon_path = '/assets/statistics_imgs/max_friendsline.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: num_of_friends, icon_path: icon_path, link_to: '', display_order: 1)
  end

  def self.avg_friends_per_snapshot(sid)
    company = get_company(sid)
    title = 'Avg. Friendliness Indications'
    tooltip = 'The amount of indications of an employee as a friend in average'
    avg_num_of_friends = get_avg_num_of_friends(sid, company.id)
    icon_path = '/assets/statistics_imgs/avg_friendsline.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: avg_num_of_friends, icon_path: icon_path, link_to: '', display_order: 1)
  end

  def self.minimum_friends_per_snapshot(sid)
    company = get_company(sid)
    title = 'Min Friendliness Indications'
    tooltip = 'The amount of indications of an employee as a friend of the least indicated employee'
    min_num_of_friends = get_min_num_of_friends(sid, company.id)
    icon_path = '/assets/statistics_imgs/min_friendsline.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: min_num_of_friends, icon_path: icon_path, link_to: '', display_order: 1)
  end

  def self.get_min_num_of_friends(sid, cid)
    relevant_network = NetworkName.where(company_id: cid, optional_relation: FRIENDSHIP).first
    return 0 if relevant_network.nil?
    min_friends = nil
    emps = Employee.where(company_id: cid)
    emps.each do |emp|
      num_of_friends = NetworkSnapshotData.where(to_employee_id: emp.id, network_id: relevant_network.id, value: 1).count
      min_friends = num_of_friends if min_friends.nil? || num_of_friends < min_friends
    end
    return min_friends.to_i
  end

  def self.get_avg_num_of_friends(sid, cid)
    relevant_network = NetworkName.where(company_id: cid, optional_relation: FRIENDSHIP).first
    return 0 if relevant_network.nil?
    sum = 0
    emps = Employee.where(company_id: cid)
    emps.each do |emp|
      sum = sum + NetworkSnapshotData.where(to_employee_id: emp.id, network_id: relevant_network.id, value: 1).count
    end
    return sum/emps.count
  end

  def self.get_num_of_friends(sid, cid)
    relevant_network = NetworkName.where(company_id: cid, optional_relation: FRIENDSHIP).first
    return 0 if relevant_network.nil?
    max_friends = 0
    emps = Employee.where(company_id: cid)
    emps.each do |emp|
      num_of_friends = NetworkSnapshotData.where(to_employee_id: emp.id, network_id: relevant_network.id, value: 1).count
      max_friends = num_of_friends if num_of_friends > max_friends
    end
    return max_friends
  end

  # def self.get_num_of_questionnairs(sid, cid)
  #   curr_snapshot = Snapshot.find(sid)
  #   relevant_snapshots = Snapshot.where(company_id: cid).select { |snapshot| (curr_snapshot.name <=> snapshot.name) > -1 }
  #   relevant_snapshots = relevant_snapshots.select { |snapshot| NetworkSnapshotData.where(snapshot_id: snapshot.id).count > 0 }
  #   return relevant_snapshots.count
  # end

  def self.get_num_of_respondents(sid, cid)
    curr_snapshot = Snapshot.find(sid)
    relevant_snapshots = Snapshot.where(company_id: cid).select { |snapshot| (curr_snapshot.name <=> snapshot.name) > -1 }
    num_of_respondents = 0
    num_of_respondents = NetworkSnapshotData.select('DISTINCT from_employee_id').where(snapshot_id: relevant_snapshots.map(&:id)).count
    return num_of_respondents
  end

  def self.find_maximum_amount_of_emails_for_employee_per_snapshot(sid)
    company = get_company(sid)
    emps = Employee.where(company_id: company.id)
    max_emp_email_amount = 0
    emps.each do |emp|
      emp_email_amount = NetworkSnapshotData.where(snapshot_id: sid, to_employee_id: emp.id).count
      max_emp_email_amount = emp_email_amount unless max_emp_email_amount > emp_email_amount
    end
    return max_emp_email_amount
  end

  def self.find_avg_amount_of_emails_for_employee_per_snapshot(sid)
    company = get_company(sid)
    network = NetworkSnapshotData.emails(company.id)
    emps = Employee.where(company_id: company.id)
    sqlstr = "SELECT COUNT(id) AS sum
              FROM network_snapshot_data 
              WHERE snapshot_id = #{sid} 
              AND network_id    = #{network}"
    res = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    s = res.first['sum'].to_i
    return s/emps.count
  end

  def self.maximum_advice_per_snapshot(sid)
    company = get_company(sid)
    title = 'Max Advice Providing Indications'
    tooltip = 'The amount of indications of an employee as an advice provider of the most indicated employee'
    num_of_advices = get_num_of_advice(company.id)
    icon_path = '/assets/statistics_imgs/max_advice.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: num_of_advices, icon_path: icon_path, link_to: '', display_order: 1)
  end

  def self.avg_advice_per_snapshot(sid)
    company = get_company(sid)
    title = 'Avg. Advice Providing Indications'
    tooltip = 'The amount of indications of an employee as an advice provider in average'
    avg_num_of_advices = get_avg_num_of_advice(company.id)
    icon_path = '/assets/statistics_imgs/avg_advice.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: avg_num_of_advices, icon_path: icon_path, link_to: '', display_order: 1)
  end

  def self.minimum_advice_per_snapshot(sid)
    company = get_company(sid)
    title = 'Min Advice Providing Indications'
    tooltip = 'The amount of indications of an employee as an advice provider of the least indicated employee'
    min_num_of_advices = get_min_num_of_advices(company.id)
    icon_path = '/assets/statistics_imgs/min_advice.png'
    CompanyStatistics.create!(snapshot_id: sid, tooltip: tooltip, statistic_title: title, statistic_data: min_num_of_advices, icon_path: icon_path, link_to: '', display_order: 1)
  end

  def self.get_min_num_of_advices(cid)
    relevant_network = NetworkName.where(company_id: cid, optional_relation: ADVICE).first
    return 0 if relevant_network.nil?
    min_advices = nil
    emps = Employee.where(company_id: cid)
    emps.each do |emp|
      num_of_advice = NetworkSnapshotData.where(to_employee_id: emp.id, network_id: relevant_network.id, value: 1).count
      min_advices = num_of_advice if min_advices.nil? || num_of_advice < min_advices
    end
    return min_advices.to_i
  end

  def self.get_avg_num_of_advice(cid)
    relevant_network = NetworkName.where(company_id: cid, optional_relation: ADVICE).first
    return 0 if relevant_network.nil?
    sum = 0
    emps = Employee.where(company_id: cid)
    emps.each do |emp|
      sum += NetworkSnapshotData.where(to_employee_id: emp.id, network_id: relevant_network.id, value: 1).count
    end
    return sum / emps.count
  end

  def self.get_num_of_advice(cid)
    relevant_network = NetworkName.where(company_id: cid, optional_relation: ADVICE).first
    return 0 if relevant_network.nil?
    max_advice = 0
    emps = Employee.where(company_id: cid)
    emps.each do |emp|
      num_of_advices = NetworkSnapshotData.where(to_employee_id: emp.id, network_id: relevant_network.id, value: 1).count
      max_advice = num_of_advices if num_of_advices > max_advice
    end
    return max_advice
  end

  def self.calc_volume_of_emails(sid)
    company = get_company(sid)
    network = NetworkSnapshotData.emails(company.id)
    sqlstr = "SELECT COUNT(id) AS sum
              FROM network_snapshot_data
              WHERE snapshot_id = #{sid}
              AND network_id    = #{network}"
    res = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    sum = res.first['sum'].to_i
    return sum
  end
end
