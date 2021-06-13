require 'write_xlsx'
require 'csv'

module InteractBackofficeHelper

  def self.active_questionnaire(cid)
    q = Questionnaire.where(company_id: cid).last
    return q
  end

  ###################### Reports ###############################
  def self.create_excel_file(file_name)
    file_path = "#{Rails.root}/tmp/#{file_name}"
    wb  = WriteXLSX.new(file_path)
    return wb
  end

  def self.create_status_excel(qid)

    res = []
    ActiveRecord::Base.transaction do

      sqlstr =
        "CREATE TABLE statconvs (id INTEGER,stat VARCHAR(20));"
      ActiveRecord::Base.connection.execute(sqlstr)

      sqlstr =
        "INSERT INTO statconvs VALUES
           (0, 'Not started'),
           (1, 'Started'),
           (2, 'Not completed'),
           (3, 'Completed');"
      ActiveRecord::Base.connection.execute(sqlstr)

      sqlstr =
        "SELECT emps.id AS id, emps.first_name || ' ' || emps.last_name AS name, emps.email AS emp_email,
                emps.phone_number, c.stat AS status, mans.first_name || ' ' || mans.last_name AS manager_name, mans.email AS manager_email
         FROM questionnaire_participants AS qp
         JOIN employees AS emps ON emps.id = qp.employee_id
         JOIN statconvs AS c ON c.id = qp.status
         LEFT JOIN employee_management_relations as emr ON emr.employee_id = emps.id
         LEFT JOIN employees AS mans ON mans.id = emr.manager_id
         WHERE
           questionnaire_id = #{qid};"
      res = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

      sqlstr =
        "DROP TABLE statconvs;"
      ActiveRecord::Base.connection.execute(sqlstr)
    end

    report_name = 'status.xlsx'

    wb = create_excel_file(report_name)
    ws = wb.add_worksheet('Status')
    ws.write('A1', 'Name')
    ws.write('B1', 'Email')
    ws.write('C1', 'Phone')
    ws.write('D1', 'Status')
    ws.write('E1', 'Link')
    ws.write('F1', 'Manager Name')
    ws.write('G1', 'Manager Email')

    ii = 2
    res.each do |r|
      link = QuestionnaireParticipant
               .where(employee_id: r['id'], questionnaire_id: qid)
               .last.try(:create_link)
      ws.write("A#{ii}", r['name'])
      ws.write("B#{ii}", r['email'])
      ws.write("C#{ii}", r['phone_number'])
      ws.write("D#{ii}", r['status'])
      ws.write("E#{ii}", link)
      ws.write("F#{ii}", r['manager_name'])
      ws.write("G#{ii}", r['manager_email'])

      ii += 1
    end

    wb.close
    return report_name
  end

  def self.create_example_excel
    report_name = 'example.xlsx'

    wb = create_excel_file(report_name)

    ## Employees
    ws = wb.add_worksheet('Employees')

    ws.write('A1', 'external_id')
    ws.write('B1', 'first_name')
    ws.write('C1', 'last_name')
    ws.write('D1', 'email')
    ws.write('E1', 'role')
    ws.write('F1', 'rank')
    ws.write('G1', 'job_title')
    ws.write('H1', 'gender')
    ws.write('I1', 'office')
    ws.write('J1', 'group')
    ws.write('K1', 'phone')

    ws.write('A2', '111')
    ws.write('B2', 'Abi')
    ws.write('C2', 'Someone')
    ws.write('D2', 'abi@comp1.com')
    ws.write('E2', 'Manager')
    ws.write('F2', '3')
    ws.write('G2', 'Head of Research')
    ws.write('H2', 'female')
    ws.write('I2', 'Netanya')
    ws.write('J2', 'R&D Central')
    ws.write('K2', '053-1122333')

    ws.write('A3', '222')
    ws.write('B3', 'Benny')
    ws.write('C3', 'Hill')
    ws.write('D3', 'benny@comp1.com')
    ws.write('E3', 'Developer')
    ws.write('F3', '1')
    ws.write('G3', 'Developer')
    ws.write('H3', 'male')
    ws.write('I3', 'Netanya')
    ws.write('J3', 'R&D Central')
    ws.write('K3', '058-9873457')

    ws.write('A4', '333')
    ws.write('B4', 'Gadi')
    ws.write('C4', 'Levi')
    ws.write('D4', 'gadi@comp1.com')
    ws.write('E4', 'Developer')
    ws.write('F4', '2')
    ws.write('G4', 'Developer')
    ws.write('H4', 'male')
    ws.write('I4', 'Ashdod')
    ws.write('J4', 'R&D South')
    ws.write('K4', '052-3141592')

    ## Groups
    ws = wb.add_worksheet('Groups')

    ws.write('A1','group_name')
    ws.write('B1','parent_group')
    ws.write('A2','Comp')
    ws.write('B2','')
    ws.write('A3','R&D Central')
    ws.write('B3','Comp')
    ws.write('A4','R&D South')
    ws.write('B4','Comp')

    wb.close
    return report_name
  end

  #################################################################
  # Create and excel file in a format that can be readily uploaded
  #################################################################
  def self.download_employees(cid, sid)
    report_name = 'employees.xlsx'
    wb = create_excel_file(report_name)

    ## Employees
    ws = wb.add_worksheet('Employees')

    ws.write('A1', 'external_id')
    ws.write('B1', 'first_name')
    ws.write('C1', 'last_name')
    ws.write('D1', 'email')
    ws.write('E1', 'role')
    ws.write('F1', 'rank')
    ws.write('G1', 'job_title')
    ws.write('H1', 'gender')
    ws.write('I1', 'office')
    ws.write('J1', 'group')
    ws.write('K1', 'phone')

    emps = Employee
      .select("emps.external_id, first_name, last_name, email, ro.name AS role,
               emps.rank_id AS rank, jt.name AS job_title, gender, o.name AS office,
               g.name AS group, phone_number")
      .from('employees AS emps')
      .joins('LEFT JOIN roles AS ro ON ro.id = emps.role_id')
      .joins('LEFT JOIN job_titles AS jt ON jt.id = emps.job_title_id')
      .joins('LEFT JOIN offices AS o ON o.id = emps.office_id')
      .joins('LEFT JOIN groups AS g ON g.id = emps.group_id')
      .where('emps.company_id = ?', cid)
      .where('emps.snapshot_id = ?', sid)
      .order('emps.email')

    ii = 1
    emps.each do |e|
      ii += 1
      ws.write("A#{ii}", e['external_id'])
      ws.write("B#{ii}", e['first_name'])
      ws.write("C#{ii}", e['last_name'])
      ws.write("D#{ii}", e['email'])
      ws.write("E#{ii}", e['role'])
      ws.write("F#{ii}", e['rank'])
      ws.write("G#{ii}", e['job_title'])
      ws.write("H#{ii}", e['gender'])
      ws.write("I#{ii}", e['office'])
      ws.write("J#{ii}", e['group'])
      ws.write("K#{ii}", e['phone_number'])
    end

    ## Groups
    ws = wb.add_worksheet('Groups')

    ws.write('A1','group_name')
    ws.write('B1','parent_group')

    groups = Group
      .select('g.name, pg.name AS parent_name')
      .from('groups AS g')
      .joins('LEFT JOIN groups AS pg ON pg.id = g.parent_group_id')
      .where("g.snapshot_id = ?", sid)
      .where("g.company_id = ?", cid)
      .order("pg.name DESC")

    ii = 1
    groups.each do |g|
      ii += 1
      ws.write("A#{ii}", g['name'])
      ws.write("B#{ii}", g['parent_name'])
    end

    wb.close
    return report_name
  end

################################# Network reports  ################################################
  #############################################################
  # Create a detailed excel report of who is connected
  # to whom in each network. The report includes all employee
  # attributes.
  #############################################################
  def self.network_report(cid, sid)
    report_name = 'network_report.xlsx'
    res, h_emps, h_networks = network_report_queries(cid, sid)

    wb = create_excel_file(report_name)
    ws = wb.add_worksheet('Report')
    ws = create_network_heading(ws)

    ii = 2
    row = 2
    res.each do |r|

      puts "In line: #{ii} out of: #{res.length}"  if (ii % 200 == 0)
      ii += 1

      femp = h_emps[r['fid'].to_s]
      temp = h_emps[r['tid'].to_s]

      if femp.nil?
        puts "Did not find employee with id: #{r['fid']}"
        next
      end
      if temp.nil?
        puts "Did not find employee with id: #{r['tid']}"
        next
      end
      network = h_networks[r['nid']]
      ws = network_report_write_row(ws, network, femp, temp, row)
      row += 1
    end

    wb.close
    return report_name
  end

  #############################################################
  # Create a report as above, but only of relations which are
  # bidirectional.
  #############################################################
  def self.bidirectional_network_report(cid, sid)
    report_name = 'bidirectional_network_report.xlsx'
    res, h_emps, h_networks, rels = network_report_queries(cid, sid)

    wb = create_excel_file(report_name)
    ws = wb.add_worksheet('Report')
    ws = create_network_heading(ws)

    ii = 2
    row = 2
    res.each do |r|

      puts "In line: #{ii} out of: #{res.length}"  if (ii % 200 == 0)
      ii += 1
      next if rels["#{r['nid']}-#{r['tid']}-#{r['fid']}"].nil?
      next if r['fid'] < r['tid']

      femp = h_emps[r['fid'].to_s]
      temp = h_emps[r['tid'].to_s]

      if femp.nil?
        puts "Did not find employee with id: #{r['fid']}"
        next
      end
      if temp.nil?
        puts "Did not find employee with id: #{r['tid']}"
        next
      end
      network = h_networks[r['nid'].to_s]

      ws = network_report_write_row(ws, network, femp, temp, row)
      row += 1
    end

    wb.close
    return report_name
  end

  def self.network_report_write_row(ws, network, femp, temp, row)
    ws.write("A#{row}", network)
    ws.write("B#{row}", "#{femp['first_name']} #{femp['last_name']}")
    ws.write("C#{row}", femp['email'])
    ws.write("D#{row}", femp['phone_number'])
    ws.write("E#{row}", femp['id_number'])
    ws.write("F#{row}", femp['external_id'])
    ws.write("G#{row}", femp['job_title'])
    ws.write("H#{row}", femp['rank_id'])
    ws.write("I#{row}", femp['role'])
    ws.write("J#{row}", femp['office'])
    ws.write("K#{row}", femp['group'])
    ws.write("L#{row}", "#{temp['first_name']} #{temp['last_name']}")
    ws.write("M#{row}", temp['email'])
    ws.write("N#{row}", temp['phone_number'])
    ws.write("O#{row}", temp['id_number'])
    ws.write("P#{row}", temp['external_id'])
    ws.write("Q#{row}", temp['job_title'])
    ws.write("R#{row}", temp['rank_id'])
    ws.write("S#{row}", temp['role'])
    ws.write("T#{row}", temp['office'])
    ws.write("U#{row}", temp['group'])
    return ws
  end

  def self.network_report_queries(cid, sid)

    sqlstr =
      "SELECT emps.id, email, first_name, last_name, ro.name AS role, rank_id, gender,
              g.name AS group, o.name AS office, jt.name AS job_title, id_number,
              emps.external_id AS external_id, emps.phone_number
       FROM employees as emps
       LEFT JOIN groups AS g ON g.id = emps.group_id
       LEFT JOIN offices AS o ON o.id = emps.office_id
       LEFT JOIN roles AS ro ON ro.id = emps.role_id
       LEFT JOIN job_titles AS jt ON jt.id = emps.job_title_id
       WHERE
         emps.snapshot_id = #{sid}"
    emps = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

    h_emps = {}
    emps.each do |e|
      h_emps[e['id'].to_s] = e
    end

    networks = NetworkName.all
    h_networks = {}
    networks.each do |n|
      h_networks[n.id.to_s] = n.name
    end

    sqlstr =
      "SELECT
         network_id AS nid, femps.id AS fid, temps.id AS tid
       FROM network_snapshot_data AS o
       JOIN employees AS femps ON femps.id = o.from_employee_id
       JOIN employees AS temps ON temps.id = o.to_employee_id
       WHERE
         o.snapshot_id = #{sid} AND
         femps.id <> temps.id AND
         o.value = 1"
    res = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

    rels = {}
    res.each do |r|
      rels["#{r['nid']}-#{r['fid']}-#{r['tid']}"] = true
    end

    return [res, h_emps, h_networks, rels]
  end

  def self.create_network_heading(ws)
    ws.write('A1', 'Network')
    ws.write('B1', 'From name')
    ws.write('C1', 'From email')
    ws.write('D1', 'From phone')
    ws.write('E1', 'From ID number')
    ws.write('F1', 'From external id')
    ws.write('G1', 'From job title')
    ws.write('H1', 'From rank')
    ws.write('I1', 'From role')
    ws.write('J1', 'From office')
    ws.write('K1', 'From group')
    ws.write('L1', 'To name')
    ws.write('M1', 'To email')
    ws.write('N1', 'To phone')
    ws.write('O1', 'To ID number')
    ws.write('P1', 'To external id')
    ws.write('Q1', 'To job title')
    ws.write('R1', 'To rank')
    ws.write('S1', 'To role')
    ws.write('T1', 'To office')
    ws.write('U1', 'To group')
    return ws
  end
######################################################################################

  def self.isolated_val(value)
    return (value == 0 ? 1 : 0)
  end


######################################################################################
  def self.measures_report(cid, sid)
    report_name = 'measures_report.xlsx'

    sqlstr =
      "SELECT
         first_name || ' ' || last_name AS emp_name, emps.external_id AS emp_id, ro.name AS role, ra.name AS rank,
         g.name AS group, o.name AS office, emps.gender, jt.name AS job_title,
         al.name AS algo_direction, nn.name AS metric_name, cds.score
       FROM cds_metric_scores AS cds
       JOIN employees AS emps ON emps.id = cds.employee_id
       JOIN company_metrics AS cm ON cm.id = cds.company_metric_id
       JOIN algorithms AS al ON al.id = cm.algorithm_id
       JOIN network_names AS nn ON nn.id = cm.network_id
       LEFT JOIN roles AS ro ON ro.id = emps.role_id
       LEFT JOIN ranks AS ra ON ra.id = emps.rank_id
       LEFT JOIN groups AS g ON g.id = cds.group_id
       LEFT JOIN offices AS o ON o.id = emps.office_id
       LEFT JOIN job_titles AS jt ON jt.id = emps.job_title_id
       where
         emps.snapshot_id = #{sid}"
    res = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

    wb = create_excel_file(report_name)
    ws = wb.add_worksheet('Report')

    ## Create heading
    ws.write('A1', 'Name')
    ws.write('B1', 'ID')
    ws.write('C1', 'Role')
    ws.write('D1', 'Rank')
    ws.write('E1', 'Group')
    ws.write('F1', 'Office')
    ws.write('G1', 'Gender')
    ws.write('H1', 'Job title')
    ws.write('I1', 'Direction')
    ws.write('J1', 'Network name')
    ws.write('K1', 'Score')

    ## Populate results
    ii = 2
    res.each do |r|
      ws.write("A#{ii}", r['emp_name'])
      ws.write("B#{ii}", r['emp_id'])
      ws.write("C#{ii}", r['role'])
      ws.write("D#{ii}", r['rank'])
      ws.write("E#{ii}", r['group'])
      ws.write("F#{ii}", r['office'])
      ws.write("G#{ii}", r['gender'])
      ws.write("H#{ii}", r['job_title'])
      ws.write("I#{ii}", r['algo_direction'])
      ws.write("J#{ii}", r['metric_name'])
      ws.write("K#{ii}", r['score'])
      ii += 1
    end

    wb.close
    return report_name
  end

  ###################### Summary report ###########################
  def self.summary_report(sid)
    cid = Snapshot.find(sid).company_id
    company_name = Company.find(cid).name
    report_name = "summary_report-#{company_name}-#{Time.now.strftime("%Y%m%d")}.xlsx"

    res, h_emps, h_networks, rels = network_report_queries(cid, sid)

    ## How many networks
    nnum = h_networks.length

    ## prepare employees hash
    h_emps.each do |k, e|
      e['uni_rels_num'] = 0
      e['bi_rels_num']  = 0
    end

    ## Count relations
    res.each do |r|
      nid = r['nid']
      fid = r['fid']
      tid = r['tid']
      emp = h_emps[fid]
      emp['uni_rels_num'] += 1
      emp['bi_rels_num'] += 1 if rels["#{nid}-#{tid}-#{fid}"]
    end

    wb = create_excel_file(report_name)
    ws = wb.add_worksheet('Report')

    ## Create heading
    ws.write('A1', 'Name')
    ws.write('B1', 'Id')
    ws.write('C1', 'job title')
    ws.write('D1', 'Rank')
    ws.write('E1', 'Role')
    ws.write('F1', 'Office')
    ws.write('G1', 'Group')
    ws.write('H1', 'Gender')
    ws.write('I1', 'Avg number relations')
    ws.write('J1', 'Avg number bi-directional relations')

    ## Write rows
    ii = 2
    h_emps.each do |k,r|
      gender = r['gender'] == '0' ? 'Male' : 'Female'

      ws.write("A#{ii}", "#{r['first_name']} #{r['last_name']}")
      ws.write("B#{ii}", r['id_number'])
      ws.write("c#{ii}", r['job_title'])
      ws.write("D#{ii}", r['rank_id'])
      ws.write("e#{ii}", r['role'])
      ws.write("F#{ii}", r['office'])
      ws.write("g#{ii}", r['group'])
      ws.write("h#{ii}", gender)
      ws.write("I#{ii}", (r['uni_rels_num'].to_f / nnum).round(2))
      ws.write("J#{ii}", (r['bi_rels_num'].to_f / nnum).round(2))
      ii += 1
    end

    wb.close
    return report_name
  end
  ##############################################################
  #
  def self.resolve_status_name(status)
    ret = nil
    case status
    when 0
      ret = 'Not started'
    when 1
      ret = 'Opened'
    when 2
      ret = 'Incomplete'
    when 3
      ret = 'Completed'
    else
      ret = 'Not started'
    end
    return ret
  end

  def self.update_questionnaire_id_in_groups_heirarchy(gid, qid)
    ancestorids = Group.get_ancestors(gid)
    ancestorids << gid
    Group.where(id: ancestorids).update_all(questionnaire_id: qid)
  end

  def self.update_employee(cid, p, qid)
    aq = Questionnaire.find(qid)

    sid = aq.snapshot_id
    eid = p['id']
    eid = eid.nil? ? p['eid'] : eid
    emp = Employee.find(eid)
    first_name = p['first_name']
    last_name = p['last_name']
    email = p['email']
    phone_number = p['phone_number']
    group_name = p['group_name']
    office = p['office']
    role = p['role']
    rank = p['rank']
    job_title = p['job_title']
    gender = p['gender']

    ## Group
    ## If no group was given the the default group is the root group. If a group name was
    ## given then look for, and if it doesn't exist create it.
    root_gid = Group.get_root_questionnaire_group(qid)
    gid = nil

    if !group_name.nil? && !group_name.empty?
      ## Clear questionnaire_id if group has changed
      old_group = emp.group
      update_questionnaire_id_in_groups_heirarchy(old_group.id, nil) if old_group.name != group_name

      group = Group.find_by(name: group_name, company_id: cid, snapshot_id: sid)
      group = Group.create!(
        name: group_name,
        company_id: cid,
        parent_group_id: root_gid,
        snapshot_id: sid,
        external_id: group_name) if group.nil?
      gid = group.id
    else
      gid = root_gid
    end

    ## Now need to add the group and all its ancestoral hierarchy to the questionnaire
    update_questionnaire_id_in_groups_heirarchy(gid, qid) if Group.find(gid).questionnaire_id != qid

    ## Office
    if !office.nil? && !office.empty?
      oid = Office.find_or_create_by!(name: office, company_id: cid).id
    end

    ## role
    if !role.nil? && !role.empty?
      roid = Role.find_or_create_by!(name: role, company_id: cid).id
    end

    ## Job title
    if !job_title.nil? && !job_title.empty?
      jtid = JobTitle.find_or_create_by!(name: job_title, company_id: cid).id
    end

    emp.update!(
      first_name: first_name,
      last_name: last_name,
      email: email,
      phone_number: phone_number,
      group_id: gid,
      office_id: oid,
      role_id: roid,
      job_title_id: jtid,
      rank_id: rank.to_i,
      gender: gender
    )

    QuestionnaireParticipant.find_or_create_by(
      employee_id: eid,
      questionnaire_id: qid
    ).create_token
  end

  def self.delete_participant(qpid)
    qp = QuestionnaireParticipant.find(qpid)
    aq = qp.questionnaire
    QuestionReply.where(questionnaire_participant_id: qp.id).delete_all
    qp.try(:delete)
    aq.update!(state: :notstarted) if !test_tab_enabled(qp.questionnaire)
    aq['state'] = Questionnaire.state_name_to_number(aq['state'])
    return aq
  end

  def self.create_employee(cid, p, aq)
    qid = aq.id
    sid = aq.snapshot_id
    first_name = p['first_name']
    last_name = p['last_name']
    email = p['email']
    phone_number = p['phone']
    group_name = p['group']
    office = p['office']
    role = p['role']
    rank = p['rank']
    job_title = p['job_title']
    gender = p['gender']

    ## Group
    ## If no group was given the the default group is the root group. If a group name was
    ## given then look for, and if it doesn't exist create it.
    root_gid = Group.get_root_questionnaire_group(qid)
    gid = nil
    if !group_name.nil? && !group_name.empty?
      group = Group.find_by(name: group_name, company_id: cid, snapshot_id: sid)
      group = Group.create!(
        name: group_name,
        company_id: cid,
        parent_group_id: root_gid,
        snapshot_id: sid,
        external_id: group_name) if group.nil?
      gid = group.id
    else
      gid = root_gid
    end

    ## Now need to add the group and all its ancestoral hierarchy to the questionnaire
    if Group.find(gid).questionnaire_id != qid
      update_questionnaire_id_in_groups_heirarchy(gid, qid)
    end

    ## Office
    oid = office.nil? ? nil : Office.find_or_create_by!(name: office, company_id: cid).id

    ## role
    roid = role.nil? ? nil : Role.find_or_create_by!(name: role, company_id: cid).id

    ## Job title
    jtid = job_title.nil? ? nil : JobTitle.find_or_create_by!(name: job_title, company_id: cid).id

    e = Employee.create!(
      email: email,
      company_id: cid,
      external_id: email.to_i(36),
      first_name: first_name,
      last_name: last_name,
      phone_number: phone_number,
      group_id: gid,
      office_id: oid,
      role_id: roid,
      job_title_id: jtid,
      rank_id: rank,
      gender: gender,
      snapshot_id: sid
    )

    QuestionnaireParticipant.create!(
      employee_id: e.id,
      questionnaire_id: qid
    ).create_token
  end

  ## Convert errors returned from load_excel to html
  def self.convert_errors_to_html(errors)
    return nil if errors.count == 0
    return errors.join('<br>')
  end

  def self.add_all_employees_as_participants(eids, aq)
    cid = aq.company_id
    emps = Employee.where(id: eids, active: true, company_id: cid)
    gids = []
    emps.each do |emp|
      gids << emp.group_id
      QuestionnaireParticipant.find_or_create_by(
        employee_id: emp.id,
        questionnaire_id: aq.id
      ).create_token
    end

    ## Now need to make sure groups are wired into the questionnaire
    qid = aq.id
    gids = gids.uniq
    gids = Group.where(questionnaire_id: nil)
                .where(id: gids)
                .pluck(:id)
    gids.each do |gid|
      update_questionnaire_id_in_groups_heirarchy(gid, qid)
    end
  end

  ###################### States ########################
  def enabled?(state, states_arr)
    ret = states_arr.include?(state)
    return '' if ret
    return 'disabled'
  end

  def self.get_sort_field(p)
    if !p['first_name|asc'].nil?
      field = 'first_name'
      dir = 'asc'
    elsif !p['first_name|desc'].nil?
      field = 'first_name'
      dir = 'desc'

    elsif !p['last_name|asc'].nil?
      field = 'last_name'
      dir = 'asc'
    elsif !p['last_name|desc'].nil?
      field = 'last_name'
      dir = 'desc'

    elsif !p['email|asc'].nil?
      field = 'email'
      dir = 'asc'
    elsif !p['email|desc'].nil?
      field = 'email'
      dir = 'desc'

    elsif !p['status|asc'].nil?
      field = 'status'
      dir = 'asc'
    elsif !p['status|desc'].nil?
      field = 'status'
      dir = 'desc'

    elsif !p['phone|asc'].nil?
      field = 'phone'
      dir = 'asc'
    elsif !p['phone|desc'].nil?
      field = 'phone'
      dir = 'desc'

    elsif !p['group|asc'].nil?
      field = 'group'
      dir = 'asc'
    elsif !p['group|desc'].nil?
      field = 'group'
      dir = 'desc'

    elsif !p['office|asc'].nil?
      field = 'office'
      dir = 'asc'
    elsif !p['office|desc'].nil?
      field = 'office'
      dir = 'desc'

    elsif !p['role|asc'].nil?
      field = 'role'
      dir = 'asc'
    elsif !p['role|desc'].nil?
      field = 'role'
      dir = 'desc'

    elsif !p['rank|asc'].nil?
      field = 'rank'
      dir = 'asc'
    elsif !p['rank|desc'].nil?
      field = 'rank'
      dir = 'desc'

    elsif !p['job_title|asc'].nil?
      field = 'job_title'
      dir = 'asc'
    elsif !p['job_title|desc'].nil?
      field = 'job_title'
      dir = 'desc'

    elsif !p['gender|asc'].nil?
      field = 'gender'
      dir = 'asc'
    elsif !p['gender|desc'].nil?
      field = 'gender'
      dir = 'desc'

    elsif !p['in_survey|asc'].nil?
      field = 'in_survey'
      dir = 'asc'
    elsif !p['in_survey|desc'].nil?
      field = 'in_survey'
      dir = 'desc'
    end

    sort_clicked = !field.nil?
    if !sort_clicked
      field = 'last_name'
      dir   = 'desc'
    end

    return [field, dir, sort_clicked]
  end

  def questions_tab_enabled(aq)
    return aq.state != 'created'
  end

  def participants_tab_enabled(aq)
    return aq.state != 'created' &&
           aq.state != 'delivery_method_ready'
  end

  def self.test_tab_enabled(aq)
    return aq.state != 'created' &&
           aq.state != 'delivery_method_ready' &&
           aq.state != 'questions_ready' &&
           aq.state != 'notstarted' &&
           aq.state != 'ready'
  end

  def reports_tab_enabled(aq)
    return aq.state == 'completed'
  end

  def self.format_questionnaire_state(state)
    ret = ''
    case state
    when 'created'
      ret = 'Created'
    when 'delivery_method_ready'
      ret = 'Delivery Method Ready'
    when 'questions_ready'
      ret = 'Questions Ready'
    when 'participants_ready'
      ret = 'Participants Ready'
    when 'notstarted'
      ret = 'Not Started'
    when 'ready'
      ret = 'Ready'
    when 'sent'
      ret = 'Sent'
    when 'processing'
      ret = 'Processing'
    when 'completed'
      ret = 'Completed'
    end
    return ret
  end

  def self.get_funnel_question_id(qid)
    funnel_question_id = QuestionnaireQuestion.where(
                           questionnaire_id: qid,
                           is_funnel_question: true,
                           active: true)
                         .last
                         .try(:id)
    return funnel_question_id
  end

  def self.create_new_question(cid, qid, question, order)
    title = question['title']
    body = question['body']
    min = question['min']
    max = question['max']
    active = question['active']

    network = NetworkName.where(company_id: cid, name: title).last
    if network.nil?
      network = NetworkName.create!(
        company_id: cid,
        name: title,
        questionnaire_id: qid
      )
    end

    funnel_question_id = get_funnel_question_id(qid)

    QuestionnaireQuestion.create!(
      company_id: cid,
      questionnaire_id: qid,
      title: title,
      body: body,
      network_id: network.id,
      min: min,
      max: max,
      order: order,
      active: active,
      depends_on_question: funnel_question_id
    )
  end

  def self.update_depends_on(qid, qqid, active)
    funnel_question_id = active ? qqid : nil
    QuestionnaireQuestion
      .where(questionnaire_id: qid, active: true)
      .where.not(is_funnel_question: true)
      .update(depends_on_question: funnel_question_id)
  end

  def self.network_metrics_report(cid,sid)
    params = Employee.active_params(cid,sid)

    cid = Snapshot.find(sid).company_id    
    quest_algorithm = QuestionnaireAlgorithm.find_by_sql("select qa.*,qq.order,e.external_id,e.first_name,e.last_name, g.name as group_name,alt.name as algorithm_name
from public.questionnaire_algorithms qa 
left join questionnaire_questions qq on qq.network_id=qa.network_id
left join employees e on e.id=qa.employee_id
left join groups g on g.id= e.group_id
left join algorithm_types alt on alt.id= qa.algorithm_type_id
where qa.snapshot_id= #{sid}  and qq.active = true
order by qa.network_id, e.external_id")
    networks = {}
    quest_algorithm.each do |res|
      networks[res.network_id] ||= {}
      unless networks[res.network_id][res.employee_id]
        networks[res.network_id][res.employee_id] = {
          :external_id => res.external_id,
          :first_name =>res.first_name,
          :last_name => res.last_name,
          :group_name => res.group_name
        }
      end
      # networks[res.network_id][res.employee_id][res.algorithm_name] = {
      #   :general => res.general_score, :group => res.group_score, :gender => res.gender_score, :rank => res.rank_score, :office => res.office_score}
      networks[res.network_id][res.employee_id][res.algorithm_name] = res
    end
    company_name = Company.find(cid).name
    cfn = CompanyFactorName.where(company_id: cid,snapshot_id: sid).order(:id)
    new_params = []
    cfn.each do |factor|
      if params.include?(factor.factor_name)
        new_params << (factor.display_name ? factor.display_name : factor.factor_name)
      end
    end
    report_name = "networkMetricsReport-#{company_name}-#{Time.now.strftime('%Y%m%d')}.xlsx"
    wb = create_excel_file(report_name)
    ws = wb.add_worksheet('Report')
    ws = create_new_report_heading(wb,ws,new_params)

    i=3
    measures = ['internal_champion','isolated','connectors','new_internal_champion','new_connectors']
    static_params = ['general_score','group_score','office_score','gender_score','rank_score']
    arr = static_params + params.map{|pa| "#{pa}_score"}
    networks = networks.sort_by { |key| key}.to_h
    idx=0
    networks.each do |quest,val|
      col = 5
      idx += 1
      val = val.sort_by { |key| key}.to_h
      val.each do |a,r|
        ws.write("A#{i}", r[:external_id])
        ws.write("B#{i}", r[:first_name])
        ws.write("C#{i}", r[:last_name])
        ws.write("D#{i}", r[:group_name])
        ws.write("E#{i}", "Q#{idx}")
        measures.each_with_index do |measure,index1|
          arr.each_with_index do |score, index2|
            j = col+index2+(arr.length * index1)
            if r[measure] 
              ws.write(i-1,j, r[measure][score].to_f)
            end
          end
        end
          i += 1
      end
    end
    wb.close
    return report_name
  end

  def self.create_new_report_heading(wb,ws,dynamic_params)
    ic_merge_format = wb.add_format({
      'align': 'center',
      'valign': 'vcenter',
      'fg_color': '#ffe699'})
    iso_merge_format = wb.add_format({
      'align': 'center',
      'valign': 'vcenter',
      'fg_color': '#b4c7e7'})
    con_merge_format = wb.add_format({
      'align': 'center',
      'valign': 'vcenter',
      'fg_color': '#c5e0b4'})  
    header_format = wb.add_format({'bold': 1})
  
    col = 5
    static_params = ['Group','office','Gender','Rank']
    cells = 1+static_params.length + dynamic_params.length

    ws.merge_range(0,col,0,col+(cells*1)-1,'Internal Champion',ic_merge_format)
    ws.merge_range(0,col+(cells*1),0,col+(cells*2)-1,'Isolated',iso_merge_format)
    ws.merge_range(0,col+(cells*2),0,col+(cells*3)-1, 'Connectors',con_merge_format)
    ws.merge_range(0,col+(cells*3),0,col+(cells*4)-1, 'New Internal Champion', ic_merge_format)
    ws.merge_range(0,col+(cells*4),0,col+(cells*5)-1, 'New Connectors', con_merge_format)
    metrics = ['Internal Champion','Isolated','Connectors','New Internal Champion','New Connectors']

    ws.write('A2', 'ID',header_format)
    ws.write('B2', 'First Name',header_format)
    ws.write('C2', 'Last Name',header_format)
    ws.write('D2', 'Group',header_format)
    ws.write('E2', 'Q',header_format)
    col = 5
    arr = static_params + dynamic_params
    for i in 0...metrics.length
      ws.write(1,col,'General',header_format)
      arr.each do |col_name|
        col += 1
        ws.write(1,col, col_name)
      end
      col += 1
    end
    return ws 
  end

end
