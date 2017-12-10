# module NetworkSnapshotNodesHelper
module NetworkSnapshotDataHelper

  NO_SNAPSHOT = -1

  def get_dynamics_employee_map_from_helper(cid, eid, interval, aid)
    snapshot_field = Snapshot.field_from_interval(interval)
    sid = Employee.find(eid).snapshot_id
    max_emps = CompanyConfigurationTable.max_emps_in_map

    direct_links = get_direct_employee_links_for_map(eid, snapshot_field, interval, sid, max_emps)

    empids = direct_links.map do |e|
      [e['source'], e['target']]
    end
    empids = empids.flatten.uniq

    nodes = get_employees_for_map(empids, snapshot_field, interval, sid, aid)
    empids_without_eid = empids.select { |e| e != eid }
    indirect_links = get_indirect_employee_links_for_map(empids_without_eid, snapshot_field, interval, sid)

    ret = {
      nodes: nodes,
      links: direct_links + indirect_links,
      result_type: 'emps',
      selected_eid: eid
    }

    return ret
  end

  ## Aggregate connections between the target emplyee and other
  ##   employees. We mark these links as direct (for the ui)
  def get_direct_employee_links_for_map(eid, snapshot_field, interval, sid, limit)
    extid = Employee.find(eid).external_id
    from_links = NetworkSnapshotData
            .select("femps.external_id AS source, temps.external_id AS target,
                     count(*) AS weight, 'direct' AS link_type")
            .joins('JOIN snapshots AS sn ON sn.id = network_snapshot_data.snapshot_id')
            .joins('JOIN employees AS femps ON femps.id = from_employee_id')
            .joins('JOIN employees AS temps ON temps.id = to_employee_id')
            .where("sn.%s = '%s'",snapshot_field, interval)
            .where("femps.external_id ='%s'", extid)
            .group('source, target')
            .order('weight desc')
            .limit(limit)

    to_links = NetworkSnapshotData
            .select("femps.external_id AS source, temps.external_id AS target,
                     count(*) AS weight, 'direct' AS link_type")
            .joins('JOIN snapshots AS sn ON sn.id = network_snapshot_data.snapshot_id')
            .joins('JOIN employees AS femps ON femps.id = from_employee_id')
            .joins('JOIN employees AS temps ON temps.id = to_employee_id')
            .where("sn.%s = '%s'",snapshot_field, interval)
            .where("temps.external_id ='%s'", extid)
            .group('source, target')
            .order('weight desc')
            .limit(limit)

    res = from_links + to_links

    res = res.map do |r|
      r['source'] = Employee.external_id_to_id_in_snapshot(r['source'], sid)
      r['target'] = Employee.external_id_to_id_in_snapshot(r['target'], sid)
      r
    end
    return res
  end

  ## Aggregate connections among the employees in the target employee's
  ##   connections group. We mark these links as indirect (for the ui)
  def get_indirect_employee_links_for_map(eids, snapshot_field, interval, sid)
    extids = Employee.where(id: eids).pluck(:external_id)
    other_links = NetworkSnapshotData
            .select("femps.external_id AS source, temps.external_id AS target,
                     count(*) AS weight, 'indirect' AS link_type")
            .joins('JOIN snapshots AS sn ON sn.id = network_snapshot_data.snapshot_id')
            .joins('JOIN employees AS femps ON femps.id = from_employee_id')
            .joins('JOIN employees AS temps ON temps.id = to_employee_id')
            .where("sn.%s = '%s'",snapshot_field, interval)
            .where("femps.external_id IN ('#{extids.join("','")}')")
            .where("temps.external_id IN ('#{extids.join("','")}')")
            .group('source, target')

    other_links = other_links.map do |r|
      r['source'] = Employee.external_id_to_id_in_snapshot(r['source'], sid)
      r['target'] = Employee.external_id_to_id_in_snapshot(r['target'], sid)
      r
    end
    return other_links
  end

  def get_dynamics_map_from_helper(cid, group_name, interval, aid)
    snapshot_field = Snapshot.field_from_interval(interval)
    last_sid = Snapshot.last_snapshot_in_interval(interval, snapshot_field)
    group = Group.where(name: group_name, snapshot_id: last_sid).last
    empids = group.extract_employees
    max_emps = CompanyConfigurationTable.max_emps_in_map

    result_type = 'groups'
    nodes = nil
    links = nil

    if (empids.length > max_emps)
      nodes = get_groups_for_map(empids, last_sid, group)
      links = get_group_links_for_map(empids, snapshot_field, interval, last_sid)
    else
      result_type = 'emps'
      nodes = get_employees_for_map(empids, snapshot_field, interval, last_sid, aid)
      links = get_employee_links_for_map(empids, snapshot_field, interval, last_sid)
    end

    ret = {
      nodes: nodes,
      links: links,
      result_type: result_type
    }.as_json
    return ret
  end

  ## For groups with more than max_emps employees use this to get nodes
  ## which are groups
  def get_groups_for_map(empids, sid, group)
    gids = group.extract_descendants_ids_and_self
    nodes = Group
            .select("g.id, g.id || '_' || g.name AS name, col.rgb AS col")
            .from('groups AS g')
            .joins("JOIN colors AS col ON col.id = g.color_id")
            .where("g.id IN (#{gids.join(',')})")
            .where("g.snapshot_id = ?", sid)
    return nodes
  end

  ## Aggregate connections among groups
  def get_group_links_for_map(empids, snapshot_field, interval, sid)
    extempids = Employee.where(id: empids).pluck(:external_id)
    links = NetworkSnapshotData
            .select('fromg.external_id AS source, tog.external_id AS target,
                     count(*) AS weight')
            .joins('JOIN employees AS fromemps ON fromemps.id = from_employee_id')
            .joins('JOIN employees AS toemps ON toemps.id = to_employee_id')
            .joins('JOIN groups AS fromg ON fromg.id = fromemps.group_id')
            .joins('JOIN groups AS tog ON tog.id = toemps.group_id')
            .joins('JOIN snapshots AS sn ON sn.id = network_snapshot_data.snapshot_id')
            .where("sn.%s = '%s'",snapshot_field, interval)
            .where("fromemps.external_id IN ('#{extempids.join("','")}')")
            .where("toemps.external_id IN ('#{extempids.join("','")}')")
            .group('source, target')
            .order('source, target')

    links = links.map do |l|
      l['source'] = Group.external_id_to_id_in_snapshot(l['source'], sid)
      l['target'] = Group.external_id_to_id_in_snapshot(l['target'], sid)
      l
    end
    return links
  end

  ## For groups with less than max_emps we get all individual employees
  def get_employees_for_map(empids, snapshot_field, interval, sid, aid)
    extids = Employee.where(id: empids).pluck(:external_id)
    nodes = Employee
            .select("emps.external_id AS id, first_name, last_name,
                     g.name AS gname, g.id AS groupid, col.rgb AS col,
                     gender, avg(cds.score) AS score")
            .from('employees AS emps')
            .joins('JOIN groups AS g ON g.id = emps.group_id')
            .joins('JOIN colors AS col ON col.id = g.color_id')
            .joins('JOIN cds_metric_scores AS cds ON cds.employee_id = emps.id')
            .joins('JOIN snapshots AS sn ON sn.id = emps.snapshot_id')
            .where("sn.%s = '%s'",snapshot_field, interval)
            .where("emps.external_id IN ('#{extids.join("','")}')")
            .where("cds.algorithm_id = %i AND cds.snapshot_id = sn.id", aid)
            .group('emps.external_id, first_name, last_name, g.name, g.id, col, gender')

    nodes = nodes.as_json
    nodes = nodes.map do |n|
      n['name'] = "#{n['first_name']} #{n['last_name']}"
      n['group_id'] = n['groupid']
      n['group_name'] = n['gname']
      n['id'] = Employee.external_id_to_id_in_snapshot(n['id'].to_s, sid)
      n
    end
    return nodes
  end

  ## Aggregate connections among emplyees
  def get_employee_links_for_map(empids, snapshot_field, interval, sid)
    extids = Employee.where(id: empids).pluck(:external_id)
    links = NetworkSnapshotData
            .select('femps.external_id AS source, temps.external_id AS target,
                     count(*) AS weight')
            .joins('JOIN employees AS femps ON femps.id = from_employee_id')
            .joins('JOIN employees AS temps ON temps.id = to_employee_id')
            .joins('JOIN snapshots AS sn ON sn.id = network_snapshot_data.snapshot_id')
            .where("sn.%s = '%s'",snapshot_field, interval)
            .where("femps.external_id IN ('#{extids.join("','")}')")
            .where("temps.external_id IN ('#{extids.join("','")}')")
            .group('source, target')

    links = links.map do |l|
      l['source'] = Employee.external_id_to_id_in_snapshot(l['source'].to_s, sid)
      l['target'] = Employee.external_id_to_id_in_snapshot(l['target'].to_s, sid)
      l
    end
    return links
  end

  def format_snapshot(p, i)
    {
      to_emp_id: p['employee_to_id'].to_i,
      from_emp_id: p['employee_from_id'].to_i,
      weight: @weight_arr[i]
    }
  end

  def weight_algorithm(snapshot_list, normalize = true)
    weight_arr = []
    if (snapshot_list.length > 0 )
      max_weight = snapshot_list.first['nsum'].to_i
      min_weight = snapshot_list.last['nsum'].to_i
      weight_arr = snapshot_list.collect{ |connection| connection['nsum'].to_i }
    else
      max_weight = 0
      min_weight = 0
      weight_arr = []
    end
    return weight_arr unless normalize
    res = create_weight_to_netowrk_node(weight_arr, min_weight, max_weight)
    return res
  end

  def calc_snapshot_email_traffic_array(emails)
    emails.group_by(&:message_id)
    sums = []
    emails.each { |email| sums.push(email.size) }
    return sums
  end

  def self.calculate_median_field_for_all_the_email_snapshot_data(median, emails)
    emails.group_by(&:message_id)
    emails.each do |email_snapshot_data_row|
      if email_snapshot_data_row.size >= median
        email_snapshot_data_row.above_median = :above
      else
        email_snapshot_data_row.above_median = :below
      end
      email_snapshot_data_row.save
    end
  end

  def calculate_significant_field_for_all_the_email_snapshot_data(snapshot, emails)
    old_snapshots = try_to_get_12_snapshots_before(snapshot)
    company = Snapshot.find(snapshot).company_id
    network = NetworkSnapshotData.emails(company)
    num_of_above_arr = NetworkSnapshotData.where(snapshot_id: old_snapshots.map{ |snap| snap.id }, network_id: network, above_median: 1)
                                          .group(:from_employee_id, :to_employee_id)
                                          .count
    old_snapshots_count = old_snapshots.count
    emails.each do |email|
      meaningfull_ratio = above_median_ratio(old_snapshots_count, email, num_of_above_arr)
      email.significant_level = :meaningfull
      #email.significant_level = :sporadic        if meaningfull_ratio < 0.6
      #email.significant_level = :not_significant if meaningfull_ratio == 0.0
      email.save!
    end
  end

  def try_to_get_12_snapshots_before(snapshot)
    old_snapshots = []
    tmp_snapshot = snapshot
    (0..11).each do |time|
      old_snapshots.push(tmp_snapshot)
      break if tmp_snapshot == tmp_snapshot.get_the_snapshot_before_this
      tmp_snapshot = tmp_snapshot.get_the_snapshot_before_this
    end
    return old_snapshots
  end

  def above_median_ratio(old_snapshots_count, email, num_of_above_arr)
    return 1.0  if old_snapshots_count <= 3 && email.above_median == 'above'
    return 0.0 if old_snapshots_count <= 3 && email.above_median == 'below'
    num_of_above = num_of_above_arr[[email.employee_from_id, email.employee_to_id]]
    return (num_of_above.to_f / old_snapshots_count.to_f)
  end

  private

  def create_weight_to_netowrk_node(weight_arr, min_weight, max_weight)
    weight_res = []
    stats = DescriptiveStatistics::Stats.new(weight_arr)
    if stats.length < 10
      m = stats.mean
      num_of_mean_add_to_arr = 10 - stats.length
      weight_list = weight_arr.dup
      (0..num_of_mean_add_to_arr).each { |i| weight_list << m }
      stats = DescriptiveStatistics::Stats.new(weight_list)
    end

    p10 = stats.value_from_percentile(10)
    p25 = stats.value_from_percentile(25)
    p50 = stats.value_from_percentile(50)
    p75 = stats.value_from_percentile(75)
    p90 = stats.value_from_percentile(90)

    weight_arr.each_with_index do |weight_node, index|
      case weight_node
      when min_weight..p10
        weight_res[index] = 1
      when p10...p25
        weight_res[index] = 2
      when p25...p50
        weight_res[index] = 3
      when p50...p75
        weight_res[index] = 4
      when p75...p90
        weight_res[index] = 5
      when p90..max_weight
        weight_res[index] = 6
      else
        puts 'create_weight_to_netowrk_node - Error: problem in calculate the weight'
      end
    end
    weight_res
  end

  def calc_meaningfull_emails(sid = NO_SNAPSHOT)
    company = Snapshot.find(sid).company_id
    network = NetworkSnapshotData.emails(company)
    if sid == NO_SNAPSHOT
      Company.all.each do |comp|
        Snapshot.order(:timestamp).where(company_id: comp.id).each do |snapshot|
          puts "In calc_meaningfull_emails() for snapshot: #{snapshot.id}"
          emails = NetworkSnapshotNodesHelper.where(snapshot_id: snapshot.id, network_id: network)
          snapshot_emails_sizes = calc_snapshot_email_traffic_array(emails)
          median = array_median(snapshot_emails_sizes)
          puts "median: #{median}"
          puts "Calculate median"
          calculate_median_field_for_all_the_email_snapshot_data(median, emails)
          puts "Calculate significant email traffic"
          calculate_significant_field_for_all_the_email_snapshot_data(snapshot, emails)
        end
      end
    else
      snapshot = Snapshot.find(sid)
      emails = NetworkSnapshotData.where(snapshot_id: snapshot.id, network_id: network)
      # snapshot_emails_sizes = calc_snapshot_email_traffic_array(emails)
      # median = array_median(snapshot_emails_sizes)
      # puts "median: #{median}"
      puts "Calculate median field for all email relations"
      # calculate_median_field_for_all_the_email_snapshot_data(median, emails)
      puts "Calculate significant email traffic"
      # calculate_significant_field_for_all_the_email_snapshot_data(snapshot, emails)
    end
  end
end
