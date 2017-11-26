require 'writeexcel'

include CalculateMeasureForCustomDataSystemHelper

module ExcelHelper

  def self.create_file(file_name)
    file_path = "#{Rails.root}/tmp/#{file_name}"
    wb  = WriteExcel.new(file_path)
    return wb
  end

  def self.create_xls_report_for_emails(cid, gids, interval, interval_type, aids, encryption_key=nil)
    report_name = ExcelHelper::create_xls_report_name('emails')

    wb = ExcelHelper.create_file(report_name)

    create_groups_part(wb, cid, gids, interval, interval_type, aids)
    create_employees_part(wb, cid, gids, interval, interval_type, aids)

    wb.close

    report_name = encrypt_report(report_name, encryption_key) if !encryption_key.nil?
    return report_name
  end

  def self.encrypt_report(report_name, key)
    source_file = "#{Rails.root}/tmp/#{report_name}"
    dest_file = "#{Rails.root}/tmp/#{report_name}.gpg"
    `cat #{source_file} | gpg --passphrase #{key} --batch --quiet --yes -c -o #{dest_file}`
    return "#{report_name}.gpg"
  end

  def self.create_employees_part(wb, cid, gids, interval, interval_type, aids)
    ws = wb.add_worksheet('Employees')

    ## Create heading
    ws.write('A1', 'Name')
    ws.write('B1', 'Email')
    ws.write('C1', 'External ID')
    ws.write('D1', 'Group Name')
    ws.write('E1', 'Interval')
    ws.write('F1', 'Algorithm')
    ws.write('G1', 'Score')

    ## Get the data
    res = get_employees_data(cid, interval, interval_type, aids)

    ## Populate results
    ii = 2
    res.each do |r|
      ws.write("A#{ii}", r[:name])
      ws.write("B#{ii}", r[:email])
      ws.write("C#{ii}", r[:external_id])
      ws.write("D#{ii}", r[:group_name])
      ws.write("E#{ii}", interval)
      ws.write("F#{ii}", r[:algorithm_name])
      ws.write("G#{ii}", r[:score])
      ii += 1
    end

    ws.protect('qwer')
    return true
  end

  def self.get_employees_data(cid, interval, interval_type, aids)
    snapshot_field = Snapshot.field_from_interval_type(interval_type)

    emps = Employee
             .select("first_name || ' ' || last_name AS name, email, employees.external_id, g.name AS group_name")
             .joins('join groups AS g ON g.id = employees.group_id')
             .joins('join snapshots AS sn ON sn.id = employees.snapshot_id')
             .where('employees.company_id = ?', cid)
             .where(["sn.%s = '%s'", snapshot_field, interval])
    emps_hash = {}
    emps.each do |emp|
      emps_hash[emp[:email]] = {
        name: emp[:name],
        external_id: emp[:external_id],
        group_name: emp[:group_name]
      }
    end

    res = CdsMetricScore
            .select('AVG(score) AS score, al.name AS algorithm_name, emps.email')
            .from('cds_metric_scores as cds')
            .joins('join employees AS emps ON emps.id = cds.employee_id')
            .joins('join algorithms AS al ON al.id = cds.algorithm_id')
            .joins('join snapshots AS sn ON sn.id = cds.snapshot_id')
            .where(["cds.company_id = %s", cid])
            .where(["cds.algorithm_id IN (%s)", aids.join(',')])
            .where(["sn.%s = '%s'", snapshot_field, interval])
            .group('algorithm_name, emps.email')
            .order('algorithm_name')
            .limit(10)

    ret = []
    res.each do |r|
      email = r[:email]
      ret << {
        name: emps_hash[email][:name],
        email: email,
        external_id: emps_hash[email][:external_id],
        group_name: emps_hash[email][:group_name],
        interval: interval,
        algorithm_name: r[:algorithm_name],
        score: r[:score]
      }
    end

    return ret
  end

  def self.create_groups_part(wb, cid, gids, interval, interval_type, aids)
    ws = wb.add_worksheet('Groups')

    ## Create heading
    ws.write('A1', 'Group ID')
    ws.write('B1', 'Group Name')
    ws.write('C1', 'Period')
    ws.write('D1', 'Algorithm')
    ws.write('E1', 'Score')

    ## Get the data
    res = get_group_data(cid, gids, interval, interval_type, aids)

    ## Populate results
    ii = 2
    res.each do |r|
      ws.write("A#{ii}", r['group_extid'])
      ws.write("B#{ii}", r['group_name'])
      ws.write("C#{ii}", interval)
      ws.write("D#{ii}", r['algorithm_name'])
      ws.write("E#{ii}", r['sum'])
      ii += 1
    end
    return true
  end

  def self.get_group_data(cid, gids, interval, interval_type, aids)
    extgids = Group.where(id: [gids]).pluck(:external_id)
    snapshot_field = Snapshot.field_from_interval_type(interval_type)
    res =
      CalculateMeasureForCustomDataSystemHelper.cds_aggregation_query(
        cid,
        interval,
        "g.external_id IN ('#{extgids.join('\',\'')}')",
        '1 = 1',
        '1 = 1',
        aids,
        snapshot_field)
    return res
  end

  def self.create_xls_report_name(tab_name)
    date = Time.now.strftime('%Y%m%d')
    return "stepahead_#{tab_name}_report_for_#{date}.xls"
  end
end
