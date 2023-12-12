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
      res = ActiveRecord::Base.connection.select_all(sqlstr).to_a

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
    ws.write('L1', 'param_a')
    ws.write('M1', 'param_b')
    ws.write('N1', 'param_c')
    ws.write('O1', 'param_d')
    ws.write('P1', 'paran_e')
    ws.write('Q1', 'param_f')
    ws.write('R1', 'param_g')
    ws.write('S1', 'param_h')
    ws.write('T1', 'param_i')
    ws.write('U1', 'param_j')
 
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
    ws.write('L2', '')
    ws.write('M2', '')
    ws.write('N2', '')
    ws.write('O2', '')
    ws.write('P2', '')
    ws.write('Q2', '')
    ws.write('R2', '')
    ws.write('S2', '')
    ws.write('T2', '')
    ws.write('U2', '')

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
    ws.write('L3', '')
    ws.write('M3', '')
    ws.write('N3', '')
    ws.write('O3', '')
    ws.write('P3', '')
    ws.write('Q3', '')
    ws.write('R3', '')
    ws.write('S3', '')
    ws.write('T3', '')
    ws.write('U3', '')

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
    ws.write('L4', '')
    ws.write('M4', '')
    ws.write('N4', '')
    ws.write('O4', '')
    ws.write('P4', '')
    ws.write('Q4', '')
    ws.write('R4', '')
    ws.write('S4', '')
    ws.write('T4', '')
    ws.write('U4', '')

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
  def self.download_employees(cid, sid,status)
    report_name = [status,'employees.xlsx'].join('_')
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
    ws.write('L1', 'param_a')
    ws.write('M1', 'param_b')
    ws.write('N1', 'param_c')
    ws.write('O1', 'param_d')
    ws.write('P1', 'paran_e')
    ws.write('Q1', 'param_f')
    ws.write('R1', 'param_g')
    ws.write('S1', 'param_h')
    ws.write('T1', 'param_i')
    ws.write('U1', 'param_j')
    if(status=='unverified')
      ws.write('V1','stepahead_id')
      ws.write('W1', 'action')
    end  
    
    emps = Employee
      .select("emps.external_id, first_name, last_name, email, is_verified, ro.name AS role,
               emps.rank_id AS rank, jt.name AS job_title, gender, o.name AS office,
               g.name AS group, phone_number,
               fa.name as param_a,
               fb.name as param_b,
               fc.name as param_c,
               fd.name as param_d,
               fe.name as param_e,
               ff.name as param_f,
               fg.name as param_g,
               emps.factor_h as param_h,
               emps.factor_i as param_i,
               emps.factor_j as param_j,emps.id")
      .from('employees AS emps')
      .joins('LEFT JOIN roles AS ro ON ro.id = emps.role_id')
      .joins('LEFT JOIN job_titles AS jt ON jt.id = emps.job_title_id')
      .joins('LEFT JOIN offices AS o ON o.id = emps.office_id')
      .joins('LEFT JOIN groups AS g ON g.id = emps.group_id')
      .joins("LEFT JOIN factor_as as fa ON fa.id = emps.factor_a_id")
      .joins("LEFT JOIN factor_bs as fb ON fb.id = emps.factor_b_id")
      .joins("LEFT JOIN factor_cs as fc ON fc.id = emps.factor_c_id")
      .joins("LEFT JOIN factor_ds as fd ON fd.id = emps.factor_d_id")
      .joins("LEFT JOIN factor_es as fe ON fe.id = emps.factor_e_id")
      .joins("LEFT JOIN factor_fs as ff ON ff.id = emps.factor_f_id")
      .joins("LEFT JOIN factor_gs as fg ON fg.id = emps.factor_g_id")
      .where('emps.company_id = ?', cid)
      .where('emps.snapshot_id = ?', sid)
      .where('is_verified '+(status=='verified' ? '=' : '!=')+'true')
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
      ws.write("L#{ii}", e['param_a'])
      ws.write("M#{ii}", e['param_b'])
      ws.write("N#{ii}", e['param_c'])
      ws.write("O#{ii}", e['param_d'])
      ws.write("P#{ii}", e['param_e'])
      ws.write("Q#{ii}", e['param_f'])
      ws.write("R#{ii}", e['param_g'])
      ws.write("S#{ii}", e['param_h'])
      ws.write("T#{ii}", e['param_i'])
      ws.write("U#{ii}", e['param_j'])
      if(status=='unverified')
        ws.write("V#{ii}",e['id'])
      end
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
    params = Employee.active_params(cid,sid)
    dynamic_params = names_of_active_params(cid,sid,params)

    wb = create_excel_file(report_name)
    ws = wb.add_worksheet('Report')
    ws = create_network_heading(ws,dynamic_params)

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
      network = h_networks[r['nid'].to_s]
      ws = network_report_write_row(ws, network, femp, temp, row,params)
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
    params = Employee.active_params(cid,sid)
    dynamic_params = names_of_active_params(cid,sid,params)


    wb = create_excel_file(report_name)
    ws = wb.add_worksheet('Report')
    ws = create_network_heading(ws,dynamic_params)

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

      ws = network_report_write_row(ws, network, femp, temp, row,params)
      row += 1
    end

    wb.close
    return report_name
  end

  def self.network_report_write_row(ws, network, femp, temp, row, active_params)
    dynamic_params = ['param_a','param_b','param_c','param_d','param_e','param_f','param_g','param_h','param_i','param_j']
    values = [network,
                  "#{femp['first_name']} #{femp['last_name']}",
                  femp['email'],
                  femp['phone_number'],
                  femp['id_number'],
                  femp['external_id'],
                  femp['job_title'],
                  femp['rank_id'],
                  femp['role'],
                  femp['office'],
                  femp['group']
    ]
    dynamic_params.each do |param| 
      values << femp[param] if active_params.include?(param)
    end
    values.concat ["#{temp['first_name']} #{temp['last_name']}",
                      temp['email'],
                      temp['phone_number'],
                      temp['id_number'],
                      temp['external_id'],
                      temp['job_title'],
                      temp['rank_id'],
                      temp['role'],
                      temp['office'],
                      temp['group']
    ]
    dynamic_params.each do |param| 
      values << temp[param] if active_params.include?(param)
    end
    values.each_with_index do |val,col|
      ws.write(row-1,col,val)
    end


    # ws.write("A#{row}", network)
    # ws.write("B#{row}", "#{femp['first_name']} #{femp['last_name']}")
    # ws.write("C#{row}", femp['email'])
    # ws.write("D#{row}", femp['phone_number'])
    # ws.write("E#{row}", femp['id_number'])
    # ws.write("F#{row}", femp['external_id'])
    # ws.write("G#{row}", femp['job_title'])
    # ws.write("H#{row}", femp['rank_id'])
    # ws.write("I#{row}", femp['role'])
    # ws.write("J#{row}", femp['office'])
    # ws.write("K#{row}", femp['group'])
    # ws.write("L#{row}", "#{temp['first_name']} #{temp['last_name']}")
    # ws.write("M#{row}", temp['email'])
    # ws.write("N#{row}", temp['phone_number'])
    # ws.write("O#{row}", temp['id_number'])
    # ws.write("P#{row}", temp['external_id'])
    # ws.write("Q#{row}", temp['job_title'])
    # ws.write("R#{row}", temp['rank_id'])
    # ws.write("S#{row}", temp['role'])
    # ws.write("T#{row}", temp['office'])
    # ws.write("U#{row}", temp['group'])
    return ws
  end

  def self.network_report_queries(cid, sid)

    sqlstr =
      "SELECT emps.id, email, first_name, last_name, ro.name AS role, rank_id, gender,
              g.name AS group, o.name AS office, jt.name AS job_title,
              fa.name as param_a,
              fb.name as param_b,
              fc.name as param_c,
              fd.name as param_d,
              fe.name as param_e,
              ff.name as param_f,
              fg.name as param_g,
              emps.factor_h as param_h,
              emps.factor_i as param_i,
              emps.factor_j as param_j,
              id_number, emps.external_id AS external_id, emps.phone_number
       FROM employees as emps
       LEFT JOIN groups AS g ON g.id = emps.group_id
       LEFT JOIN offices AS o ON o.id = emps.office_id
       LEFT JOIN roles AS ro ON ro.id = emps.role_id
       LEFT JOIN job_titles AS jt ON jt.id = emps.job_title_id
       LEFT JOIN factor_as as fa ON fa.id = emps.factor_a_id
       LEFT JOIN factor_bs as fb ON fb.id = emps.factor_b_id
       LEFT JOIN factor_cs as fc ON fc.id = emps.factor_c_id
       LEFT JOIN factor_ds as fd ON fd.id = emps.factor_d_id
       LEFT JOIN factor_es as fe ON fe.id = emps.factor_e_id
       LEFT JOIN factor_fs as ff ON ff.id = emps.factor_f_id
       LEFT JOIN factor_gs as fg ON fg.id = emps.factor_g_id
 
       WHERE
         emps.snapshot_id = #{sid}"
    emps = ActiveRecord::Base.connection.select_all(sqlstr).to_a

    h_emps = {}
    emps.each do |e|
      h_emps[e['id'].to_s] = e
    end

    # networks = NetworkName.all
    # h_networks = {}
    # networks.each do |n|
    #   h_networks[n.id.to_s] = n.name
    # end
    questionaire_questions = Questionnaire.where(snapshot_id: sid).first
    .questionnaire_questions.where(active: true)
    h_networks = {}
    questionaire_questions.each do |qq|
      h_networks[qq.network_id.to_s] = qq.title
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
    res = ActiveRecord::Base.connection.select_all(sqlstr).to_a

    rels = {}
    res.each do |r|
      rels["#{r['nid']}-#{r['fid']}-#{r['tid']}"] = true
    end

    return [res, h_emps, h_networks, rels]
  end

  def self.create_network_heading(ws,dynamic_params)
    puts "dynamic params ==   #{dynamic_params}"
    header = ['Network','From name','From email','From phone','From ID number','From external id','From job title','From rank','From role','From office','From group']
    dynamic_params.each{|param| header << "From #{param}"}
    header.concat ['To name','To email','To phone','To ID number','To external id','To job title','To rank','To role','To office','To group']
    dynamic_params.each{|param| header << "To #{param}"}
    header.each_with_index do |val,col|
      ws.write(0,col,val)
    end
    # ws.write('A1', 'Network')
    # ws.write('B1', 'From name')
    # ws.write('C1', 'From email')
    # ws.write('D1', 'From phone')
    # ws.write('E1', 'From ID number')
    # ws.write('F1', 'From external id')
    # ws.write('G1', 'From job title')
    # ws.write('H1', 'From rank')
    # ws.write('I1', 'From role')
    # ws.write('J1', 'From office')
    # ws.write('K1', 'From group')
    # ws.write('L1', 'To name')
    # ws.write('M1', 'To email')
    # ws.write('N1', 'To phone')
    # ws.write('O1', 'To ID number')
    # ws.write('P1', 'To external id')
    # ws.write('Q1', 'To job title')
    # ws.write('R1', 'To rank')
    # ws.write('S1', 'To role')
    # ws.write('T1', 'To office')
    # ws.write('U1', 'To group')
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
         fa.name as param_a,
         fb.name as param_b,
         fc.name as param_c,
         fd.name as param_d,
         fe.name as param_e,
         ff.name as param_f,
         fg.name as param_g,
         emps.factor_h as param_h,
         emps.factor_i as param_i,
         emps.factor_j as param_j,
         al.name AS algo_direction, qq.title AS metric_name, cds.score
       FROM cds_metric_scores AS cds
       JOIN employees AS emps ON emps.id = cds.employee_id
       JOIN company_metrics AS cm ON cm.id = cds.company_metric_id
       JOIN algorithms AS al ON al.id = cm.algorithm_id
       JOIN network_names AS nn ON nn.id = cm.network_id
       JOIN questionnaire_questions qq ON qq.network_id = nn.id
       LEFT JOIN roles AS ro ON ro.id = emps.role_id
       LEFT JOIN ranks AS ra ON ra.id = emps.rank_id
       LEFT JOIN groups AS g ON g.id = emps.group_id
       LEFT JOIN offices AS o ON o.id = emps.office_id
       LEFT JOIN job_titles AS jt ON jt.id = emps.job_title_id
       LEFT JOIN factor_as as fa ON fa.id = emps.factor_a_id
       LEFT JOIN factor_bs as fb ON fb.id = emps.factor_b_id
       LEFT JOIN factor_cs as fc ON fc.id = emps.factor_c_id
       LEFT JOIN factor_ds as fd ON fd.id = emps.factor_d_id
       LEFT JOIN factor_es as fe ON fe.id = emps.factor_e_id
       LEFT JOIN factor_fs as ff ON ff.id = emps.factor_f_id
       LEFT JOIN factor_gs as fg ON fg.id = emps.factor_g_id
       where
         emps.snapshot_id = #{sid}"
    res = ActiveRecord::Base.connection.select_all(sqlstr).to_a
    params = Employee.active_params(cid,sid)
    dynamic_params = names_of_active_params(cid,sid,params)

    wb = create_excel_file(report_name)
    ws = wb.add_worksheet('Report')

    ## Create heading
    heading = ['Name','ID','Role','Rank','Group','Office','Gender','Job title']
    heading.concat(dynamic_params)
    heading.concat(['Direction','Network name','Score'])
    ws.write_row("A1",heading)
    # ws.write('A1', 'Name')
    # ws.write('B1', 'ID')
    # ws.write('C1', 'Role')
    # ws.write('D1', 'Rank')
    # ws.write('E1', 'Group')
    # ws.write('F1', 'Office')
    # ws.write('G1', 'Gender')
    # ws.write('H1', 'Job title')
    # ws.write('I1', 'Direction')
    # ws.write('J1', 'Network name')
    # ws.write('K1', 'Score')

    ## Populate results
    # ii = 2
    # res.each do |r|
    #   ws.write("A#{ii}", r['emp_name'])
    #   ws.write("B#{ii}", r['emp_id'])
    #   ws.write("C#{ii}", r['role'])
    #   ws.write("D#{ii}", r['rank'])
    #   ws.write("E#{ii}", r['group'])
    #   ws.write("F#{ii}", r['office'])
    #   ws.write("G#{ii}", r['gender'])
    #   ws.write("H#{ii}", r['job_title'])
    #   ws.write("I#{ii}", r['algo_direction'])
    #   ws.write("J#{ii}", r['metric_name'])
    #   ws.write("K#{ii}", r['score'])
    #   ii += 1
    # end
    all_params = ['param_a','param_b','param_c','param_d','param_e','param_f','param_g','param_h','param_i','param_j']
    ii = 1
    res.each do |r|
      values = [ 
        r['emp_name'],
        r['emp_id'],
        r['role'],
        r['rank'],
        r['group'],
        r['office'],
        r['gender'],
        r['job_title']
      ]
      all_params.each do |param| 
        values << r[param] if params.include?(param)
      end
      values.concat([
        r['algo_direction'],
        r['metric_name'],
        r['score']
      ])
      ws.write_row(ii,0,values)
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
    when 4
      ret = 'Unverified'  
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

  def self.delete_participant(qp,user_id)
    aq = qp.questionnaire
    QuestionReply.where(questionnaire_participant_id: qp.id).delete_all
    emp = Employee.find(qp.employee_id)
    emps_in_group = Employee.where(group_id: emp.group_id)
    if emps_in_group.length == 1
      Group.find(emp.group_id).destroy
    end
    emp.destroy
    qp.try(:delete)
    aq.update!(state: :notstarted) if !test_tab_enabled(aq)
    cache_key = "groups-comapny_id-uid-#{user_id}-cid-#{aq.company_id}-sid-#{aq.snapshot_id}-qid-#{aq.id}"
    res = cache_delete(cache_key,'')
    return aq
  end

  def self.remove_questionnaire_participans(qid,user_id)
    questionnaire = Questionnaire.find(qid)
    snapshot_id =  questionnaire.snapshot_id
    QuestionnaireParticipant.where(questionnaire_id: qid).where.not(employee_id: -1).destroy_all
    Group.where(snapshot_id: snapshot_id).destroy_all
    Employee.where(snapshot_id: snapshot_id).destroy_all
    cache_key = "groups-comapny_id-uid-#{user_id}-cid-#{questionnaire.company_id}-sid-#{snapshot_id}-qid-#{questionnaire.id}"
    cache_delete(cache_key,'')
 end

  def self.create_employee(cid, p, aq)
    qid = aq.id
    sid = aq.snapshot_id
    first_name = p['first_name']
    last_name = p['last_name']
    email = p['email']
    phone_number = p['phone']
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

  def self.add_all_employees_as_participants(eids, aq, user_id)
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
    cache_key = "groups-comapny_id-uid-#{user_id}-cid-#{cid}-sid-#{aq.snapshot_id}-qid-#{aq.id}"
    res = cache_delete(cache_key,'')

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

  def self.names_of_active_params(cid,sid,params)
   cfn = CompanyFactorName.where(company_id: cid,snapshot_id: sid).order(:id)
    new_params = []
    cfn.each do |factor|
      if params.include?(factor.factor_name)
        new_params << (factor.display_name ? factor.display_name : factor.factor_name)
      end
    end
    return new_params
  end

  def self.network_metrics_report(cid,sid)
    params = Employee.active_params(cid,sid)

    cid = Snapshot.find(sid).company_id    
    quest_algorithm = QuestionnaireAlgorithm.find_by_sql("select qa.*,qq.order,qq.title as q_title,e.external_id,e.first_name,e.last_name, g.name as group_name,alt.name as algorithm_name
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
          :group_name => res.group_name,
          :question_title => res.q_title
        }
      end
      # networks[res.network_id][res.employee_id][res.algorithm_name] = {
      #   :general => res.general_score, :group => res.group_score, :gender => res.gender_score, :rank => res.rank_score, :office => res.office_score}
      networks[res.network_id][res.employee_id][res.algorithm_name] = res
    end
    company_name = Company.find(cid).name
    new_params = names_of_active_params(cid,sid,params)
    # cfn = CompanyFactorName.where(company_id: cid,snapshot_id: sid).order(:id)
    # new_params = []
    # cfn.each do |factor|
    #   if params.include?(factor.factor_name)
    #     new_params << (factor.display_name ? factor.display_name : factor.factor_name)
    #   end
    # end
    report_name = "network_metrics_report.xlsx"
    wb = create_excel_file(report_name)
    ws = wb.add_worksheet('Report')
    ws = create_new_report_heading(wb,ws,new_params)

    i=3
    measures = ['internal_champion','isolated','connectors','new_internal_champion','new_connectors']
    static_params = ['general_score','group_score','office_score','gender_score','rank_score']
    affected_measures = ['new_connectors','new_internal_champion']
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
        ws.write("E#{i}", r[:question_title])
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


  def self.get_companies
    sqlstr = "select c.id, c.name, COALESCE(count(q.id),0)as survey_num,  COALESCE(sum(p_num),0) as participants_num
    from companies c left join questionnaires q on c.id=q.company_id
    left join (select questionnaire_id, count(*) as p_num from questionnaire_participants where employee_id != -1 group by questionnaire_id ) sp
    on sp.questionnaire_id=q.id
    group by c.id,c.name
    order by c.id desc"

    res = ActiveRecord::Base.connection.select_all(sqlstr).to_a
    return res
  end

  def self.get_company_users(cid,user)
    users = User.where(company_id: cid)
    user_list = []
    users.each do |u|
      permitted_quests = QuestionnairePermission.select(:id,:user_id,:questionnaire_id,:level).where(user_id: u.id)
      user = {
        id: u.id,
        first_name: u.first_name,
        last_name: u.last_name,
        email: u.email,
        password: u.password_digest,
        user_type: u.role,
        is_allowed_create_questionnaire: u.is_allowed_create_questionnaire,
        is_allowed_add_users: u.is_allowed_add_users,
        permitted_quests: permitted_quests.as_json
      }
      user_list << user
    end
    return user_list
  end

  def self.get_user_company(user,company_id=nil,qid=nil)
    if user.super_admin?
      return  company_id unless company_id.nil?
      if qid
        q = Questionnaire.find(qid)
        return  q.company_id if q
      end
      return Company.where(active: true).last.id
    end
    return user.company_id
  end

  def self.create_new_company(name)
    company = Company.create!({
      name: name,
      product_type: :questionnaire_only
    })
    return company
  end

  def self.create_new_user(cid,user)
    first_name = user['first_name']
    email = user['email']
    password = user['password']
    last_name = user['last_name']
    user_type = user['user_type']
    is_allowed_add_users = (user_type == 'admin' ? user['is_allowed_add_users'] : false)
    is_allowed_create_questionnaire = (user_type == 'admin' ? user['is_allowed_create_questionnaire'] : false)

    u = User.create!({
      company_id: cid,
      first_name: first_name,
      email: email,
      password: password,
      role: user_type,
      last_name: last_name,
      is_allowed_add_users: is_allowed_add_users,
      is_allowed_create_questionnaire: is_allowed_create_questionnaire,
      active: true
    })
    if u.role != 'admin'
        user['permitted_quests'].each do |permit|
          QuestionnairePermission.create!(questionnaire_id: permit['item_id'],user_id: u.id,company_id:cid,level: 'admin')
        end
      end
    
    return u
  end

  def self.update_user(cid,user)
    u = User.find(user['id'])
    # password = (user['password'] ==  u.password_digest ? u.password : user['password'])
    user_type = user['user_type']
    is_allowed_add_users = (user_type == 'admin' ? user['is_allowed_add_users'] : false)
    is_allowed_create_questionnaire = (user_type == 'admin' ? user['is_allowed_create_questionnaire'] : false)
    u.update_attributes!(
      first_name: user['first_name'],
      last_name: user['last_name'],
      email: user['email'],
      role: user_type,
      is_allowed_add_users: is_allowed_add_users,
      is_allowed_create_questionnaire: is_allowed_create_questionnaire
      )
    if (user['password'] !=  u.password_digest)
      u.update!(password: user['password'])
    end
    if u.role != 'admin'
      u.questionnaire_permissions.destroy_all
      user['permitted_quests'].each do |permit|
        level = (permit['level'].blank? ? 'admin' : permit['level'])
        QuestionnairePermission.create!(questionnaire_id: permit['item_id'],user_id: u.id,company_id:cid,level: level)
      end
    end
    return u
  end

end
