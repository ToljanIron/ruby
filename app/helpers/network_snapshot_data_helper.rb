# frozen_string_literal: true

require './app/helpers/algorithms_helper.rb'

module NetworkSnapshotDataHelper
  include AlgorithmsHelper

  NO_SNAPSHOT ||= -1

  G_INSIDE  ||= 1
  G_OUTSIDE ||= 2
  G_NOT_IN  ||= 3

  ##################### Map for Interfaces ##################################

  ##########################################################################
  # - Get groups with top traffic from cgid
  # - Get groups with top traffic to cgid
  # - Get taraffic between those groups
  # - Get traffic between cgid and the rest of the groups
  # - Package and send
  ###########################################################################
  def get_interfaces_map_from_helper(cid, interval, cgid, gids)
    snapshot_field = Snapshot.field_from_interval(interval)
    sid = Snapshot.last_snapshot_in_interval(interval, snapshot_field)
    nid = NetworkName.get_emails_network(cid)
    cg = Group.find(cgid.to_i)
    extids = Group.where(id: gids).pluck(:external_id)

    ## Top traffic from cgid (Sending)
    ret = interfaces_traffic_volumes_query(G_INSIDE, G_OUTSIDE, snapshot_field, interval, cid, nid, cg.nsleft, cg.nsright, extids, 10)
    topextids = []
    ret.each do |r|
      topextids << r['toextid']
    end

    ## Top traffic to cgid (Receiving)
    ret = interfaces_traffic_volumes_query(G_OUTSIDE, G_INSIDE, snapshot_field, interval, cid, nid, cg.nsleft, cg.nsright, extids, 10)
    ret.each do |r|
      topextids | [r['fromextid']]
    end

    links = []

    # Traffic volumes (Receiving)
    ret = interfaces_traffic_volumes_query(G_OUTSIDE, G_INSIDE, snapshot_field, interval, cid, nid, cg.nsleft, cg.nsright, topextids)
    ret.each do |r|
      links << {
        source: Group.external_id_to_id_in_snapshot(r['fromextid'], sid),
        target: cgid.to_i,
        volume: r['vol']
      }
    end

    # Traffic volumes (Sending)
    ret = interfaces_traffic_volumes_query(G_INSIDE, G_OUTSIDE, snapshot_field, interval, cid, nid, cg.nsleft, cg.nsright, topextids)
    ret.each do |r|
      links << {
        source: cgid.to_i,
        target: Group.external_id_to_id_in_snapshot(r['toextid'], sid),
        volume: r['vol']
      }
    end

    # Traffic outside cgid
    ret = interfaces_traffic_volumes_query(G_OUTSIDE, G_OUTSIDE, snapshot_field, interval, cid, nid, cg.nsleft, cg.nsright, topextids)
    ret.each do |r|
      sgid = Group.external_id_to_id_in_snapshot(r['fromextid'], sid)
      tgid = Group.external_id_to_id_in_snapshot(r['toextid'], sid)
      next if sgid == tgid
      links << {
        source: sgid,
        target: tgid,
        volume: r['vol']
      }
    end

    # Traffic inside cgid only
    ret = interfaces_traffic_volumes_query(G_INSIDE, G_INSIDE, snapshot_field, interval, cid, nid, cg.nsleft, cg.nsright, topextids, nil)
    links << {
      source: cgid.to_i,
      target: cgid.to_i,
      volume: ret[0]['vol']
    } if ret.length > 0

    # Traffic to other groups
    ret = interfaces_traffic_volumes_query(G_INSIDE, G_NOT_IN, snapshot_field, interval, cid, nid, cg.nsleft, cg.nsright, topextids, nil)
    links << {
      source: cgid.to_i,
      target: -1,
      volume: ret[0]['vol']
    } if ret.length > 0

    # Traffic from other groups
    ret = interfaces_traffic_volumes_query(G_NOT_IN, G_INSIDE, snapshot_field, interval, cid, nid, cg.nsleft, cg.nsright, topextids, nil)
    links << {
      source: -1,
      target: cgid.to_i,
      volume: ret[0]['vol']
    } if ret.length > 0

    ## Get all groups
    topextids << cg.external_id
    group_size = "select count(*) from employees where group_id = g.id"
    name_field = CompanyConfigurationTable.is_investigation_mode? ? 'english_name' : 'name'
    name_select_str = "g.#{name_field}"
    if CompanyConfigurationTable.is_investigation_mode?
      name_select_str = "g.id || '_' || #{name_select_str}"
    end
    groups = Group.select("g.id, #{name_select_str} AS name, col.rgb AS col, g.snapshot_id,
                           g.hierarchy_size, (#{group_size}) AS group_size")
                  .from('groups AS g')
                  .joins('JOIN colors AS col ON col.id = g.color_id')
                  .where('g.snapshot_id = ?', sid)
                  .where("g.external_id in ('#{topextids.join('\',\'')}')")

    return {
      links: links,
      nodes: groups,
      selected_group: cgid.to_i
    }
  end

  ############################################################################
  # This query counts traffic between a certain hierarchy and other groups.
  #  - fromside and toside take values of 1 or 2. 1 for traffic inside the
  #    hierarcy, 2 for traffic outside of it
  #  - snfield is the name of the snapshot type (month, half year, etc ..
  #  - interval is the name of the snapshot interval
  #  - cid, nid ...
  #  - nsleft, nsright are the nested set indicators of the hierarchy top group
  #  - extids is the list of the groups we're interesed in.
  #  - limit determines how many records to extract
  ############################################################################
  def interfaces_traffic_volumes_query(fromside, toside, snfield, interval, cid, nid, nsleft, nsright, extids, limit = nil)
    select_str = 'SELECT COUNT(*) AS vol'
    select_str = "#{select_str},tg.external_id AS toextid" if toside == G_OUTSIDE
    select_str = "#{select_str},fg.external_id AS fromextid" if fromside == G_OUTSIDE

    fhierarchy_dir = "(fg.nsleft >= #{nsleft} AND fg.nsright <= #{nsright})" if fromside == G_INSIDE
    fhierarchy_dir = "(fg.nsleft < #{nsleft} OR fg.nsright > #{nsright})" if fromside != G_INSIDE
    thierarchy_dir = "(tg.nsleft >= #{nsleft} AND tg.nsright <= #{nsright})" if toside == G_INSIDE
    thierarchy_dir = "(tg.nsleft < #{nsleft} OR tg.nsright > #{nsright})" if toside != G_INSIDE

    extidsstr = extids.join("','")

    fextidswhere = '1 = 1'
    fextidswhere = "fg.external_id in ('#{extidsstr}')"     if (fromside == G_OUTSIDE)
    fextidswhere = "fg.external_id not in ('#{extidsstr}')" if (fromside == G_NOT_IN)
    textidswhere = '1 = 1'
    textidswhere = "tg.external_id in ('#{extidsstr}')"     if (toside == G_OUTSIDE)
    textidswhere = "tg.external_id not in ('#{extidsstr}')" if (toside == G_NOT_IN)

    groupby = 'GROUP BY' if fromside == G_OUTSIDE || toside == G_OUTSIDE
    groupby = "#{groupby} fg.external_id" if fromside == G_OUTSIDE
    groupby = "#{groupby}, " if fromside == G_OUTSIDE && toside == G_OUTSIDE
    groupby = "#{groupby} tg.external_id" if toside == G_OUTSIDE

    sqlstr = "
      #{select_str}
      FROM network_snapshot_data AS nsd
      JOIN employees AS femps ON femps.id = nsd.from_employee_id
      JOIN groups AS fg ON fg.id = femps.group_id
      JOIN employees AS temps ON temps.id = nsd.to_employee_id
      JOIN groups AS tg ON tg.id = temps.group_id
      JOIN snapshots AS sn ON sn.id = nsd.snapshot_id
      WHERE
        #{fhierarchy_dir} AND
        #{thierarchy_dir} AND
        #{fextidswhere} AND
        #{textidswhere} AND
        sn.#{snfield} = '#{interval}' AND
        nsd.company_id = #{cid} AND
        nsd.network_id = #{nid}"
    sqlstr = "#{sqlstr} #{groupby}" unless groupby.nil?
    sqlstr = "#{sqlstr} ORDER BY vol DESC LIMIT #{limit}" unless limit.nil?

    return ActiveRecord::Base.connection.select_all(sqlstr).to_hash
  end

  ##################### Map for Dynamics ##################################
  def get_dynamics_employee_map_from_helper(_cid, eid, interval, aid)
    snapshot_field = Snapshot.field_from_interval(interval)
    sid = Employee.find(eid).snapshot_id
    max_emps = CompanyConfigurationTable.max_emps_in_map

    direct_links = get_direct_employee_links_for_map(eid, snapshot_field, interval, sid, max_emps)

    empids = direct_links.map do |e|
      [e[:id1], e[:id2]]
    end
    empids = empids.flatten.uniq

    nodes = get_employees_for_map(empids, snapshot_field, interval, sid, aid)
    empids_without_eid = empids.reject { |e| e == eid }
    indirect_links = get_indirect_employee_links_for_map(empids_without_eid, snapshot_field, interval, sid)

    groups = get_groups_from_emps( nodes.map { |e| e['group_id'] }.uniq )

    ret = {
      nodes: nodes,
      links: direct_links + indirect_links,
      groups: groups,
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
                     count(*) AS w, 'direct' AS link_type")
                 .joins('JOIN snapshots AS sn ON sn.id = network_snapshot_data.snapshot_id')
                 .joins('JOIN employees AS femps ON femps.id = from_employee_id')
                 .joins('JOIN employees AS temps ON temps.id = to_employee_id')
                 .where("sn.%s = '%s'", snapshot_field, interval)
                 .where("femps.external_id ='%s'", extid)
                 .group('source, target')
                 .order('w desc')
                 .limit(limit)

    to_links = NetworkSnapshotData
               .select("femps.external_id AS source, temps.external_id AS target,
                     count(*) AS w, 'direct' AS link_type")
               .joins('JOIN snapshots AS sn ON sn.id = network_snapshot_data.snapshot_id')
               .joins('JOIN employees AS femps ON femps.id = from_employee_id')
               .joins('JOIN employees AS temps ON temps.id = to_employee_id')
               .where("sn.%s = '%s'", snapshot_field, interval)
               .where("temps.external_id ='%s'", extid)
               .group('source, target')
               .order('w desc')
               .limit(limit)

    res = from_links + to_links

    res = res.map do |r|
      {
        id1: Employee.external_id_to_id_in_snapshot(r['source'], sid).to_i,
        id2: Employee.external_id_to_id_in_snapshot(r['target'], sid).to_i,
        w: r['w'],
        id: nil
      }
    end
    return res
  end

  ## Aggregate connections among the employees in the target employee's
  ##   connections group. We mark these links as indirect (for the ui)
  def get_indirect_employee_links_for_map(eids, snapshot_field, interval, sid)
    extids = Employee.where(id: eids).pluck(:external_id)
    other_links = NetworkSnapshotData
                  .select("femps.external_id AS source, temps.external_id AS target,
                     count(*) AS w, 'indirect' AS link_type")
                  .joins('JOIN snapshots AS sn ON sn.id = network_snapshot_data.snapshot_id')
                  .joins('JOIN employees AS femps ON femps.id = from_employee_id')
                  .joins('JOIN employees AS temps ON temps.id = to_employee_id')
                  .where("sn.%s = '%s'", snapshot_field, interval)
                  .where("femps.external_id IN ('#{extids.join("','")}')")
                  .where("temps.external_id IN ('#{extids.join("','")}')")
                  .group('source, target')

    other_links = other_links.map do |r|
      {
      id1: Employee.external_id_to_id_in_snapshot(r['source'], sid),
      id2: Employee.external_id_to_id_in_snapshot(r['target'], sid),
      w: r['w'],
      id: nil
      }
    end
    return other_links
  end

  def get_dynamics_map_from_helper(_cid, group_name, interval, aid)
    snapshot_field = Snapshot.field_from_interval(interval)
    last_sid = Snapshot.last_snapshot_in_interval(interval, snapshot_field)
    group = Group.where(name: group_name, snapshot_id: last_sid).last
    if group.nil?
      group = Group.where(english_name: group_name, snapshot_id: last_sid).last
    end
    empids = group.extract_employees
    max_emps = CompanyConfigurationTable.max_emps_in_map

    result_type = 'groups'
    nodes = nil
    links = nil

    if empids.length > max_emps
      nodes = get_groups_for_map(last_sid, group)
      links = get_group_links_for_map(empids, snapshot_field, interval, last_sid, group)
    else
      result_type = 'emps'
      nodes = get_employees_for_map(empids, snapshot_field, interval, last_sid, aid)
      links = get_employee_links_for_map(empids, snapshot_field, interval, last_sid)
    end

    groups = get_groups_from_emps( nodes.map { |e| e['group_id'] }.uniq )

    ret = {
      nodes: nodes,
      links: links,
      groups: groups,
      result_type: result_type
    }.as_json
    return ret
  end

  def get_groups_from_emps(gids)
    groups = Group.select('id AS gid, color_id, name, parent_group_id AS parentid')
                  .where(id: gids)
    return groups
  end

  ## For groups with more than max_emps employees use this to get nodes
  ## which are groups
  def get_groups_for_map(sid, group)
    gids = group.extract_l2_ids_and_self
    nodes = Group
            .select("g.id, g.id || '_' || g.english_name AS name, col.rgb AS col")
            .from('groups AS g')
            .joins('JOIN colors AS col ON col.id = g.color_id')
            .where("g.id IN (#{gids.join(',')})")
            .where('g.snapshot_id = ?', sid)
    return nodes
  end

  ## Aggregate connections among groups
  def get_group_links_for_map(empids, snapshot_field, interval, sid, group)
    extempids = Employee.where(id: empids).pluck(:external_id)
    ar_links = NetworkSnapshotData
               .select('fromg.external_id AS source, tog.external_id AS target,
                     count(*) AS weight')
               .joins('JOIN employees AS fromemps ON fromemps.id = from_employee_id')
               .joins('JOIN employees AS toemps ON toemps.id = to_employee_id')
               .joins('JOIN groups AS fromg ON fromg.id = fromemps.group_id')
               .joins('JOIN groups AS tog ON tog.id = toemps.group_id')
               .joins('JOIN snapshots AS sn ON sn.id = network_snapshot_data.snapshot_id')
               .where("sn.%s = '%s'", snapshot_field, interval)
               .where("fromemps.external_id IN ('#{extempids.join("','")}')")
               .where("toemps.external_id IN ('#{extempids.join("','")}')")
               .group('fromg.external_id, tog.external_id')
               .order('fromg.external_id, tog.external_id')

    extids = group.extract_l2_external_ids
    extids_cond = "topg.external_id IN ('#{extids.join('\',\'')}')"
    sqlstr =
      "SELECT g.external_id AS dgroup, topg.external_id AS pgroup
      FROM groups AS g
      JOIN groups AS topg ON topg.nsleft <= g.nsleft AND topg.nsright >= g.nsright
      WHERE
        #{extids_cond} AND
        topg.snapshot_id = #{sid} AND
        g.snapshot_id = #{sid}"
    res = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

    l2_map = {}
    res.each do |r|
      l2_map[r['dgroup']] = r['pgroup']
    end

    ## Collapse hierarchies into the top L2 groups
    links_map = {}
    ar_links.each do |l|
      src1 = l['source']
      src2 = l2_map[src1]
      src3 = src2.nil? ? l['source'] : src2
      src = Group.external_id_to_id_in_snapshot(src3, sid)

      trgt = l['target']
      trgt = l2_map[trgt]
      trgt = trgt.nil? ? l['target'] : trgt
      trgt = Group.external_id_to_id_in_snapshot(trgt, sid)

      if links_map[[src, trgt]].nil?
        links_map[[src, trgt]] = l['weight']
      else
        links_map[[src, trgt]] += l['weight']
      end
    end

    ## Convert to result format
    links = []
    links_map.each do |k, v|
      elem = {
        source: k[0],
        target: k[1],
        weight: v
      }
      links.push elem
    end

    return links
  end

  ## For groups with less than max_emps we get all individual employees
  def get_employees_for_map(empids, snapshot_field, interval, sid, aid)
    extids = Employee.where(id: empids).pluck(:external_id)
    nodes = Employee
            .select("first_name, last_name, emps.group_id, g.color_id, gender,
                     emps.external_id, avg(cds.score) AS d, o.name AS office_name, g.name,
                     jt.name AS job_title_name, rank_id, ro.name AS role_name, email")
            .from('employees AS emps')
            .joins("LEFT JOIN cds_metric_scores AS cds ON cds.employee_id = emps.id AND cds.algorithm_id = #{aid}")
            .joins('JOIN snapshots AS sn ON sn.id = emps.snapshot_id')
            .joins('LEFT JOIN offices AS o ON o.id = emps.office_id')
            .joins('JOIN groups AS g ON g.id = emps.group_id')
            .joins('LEFT JOIN job_titles AS jt ON jt.id = emps.job_title_id')
            .joins('LEFT JOIN roles AS ro ON ro.id = emps.role_id')
            .where("sn.%s = '%s'", snapshot_field, interval)
            .where("emps.external_id IN ('#{extids.join("','")}')")
            .group('first_name, last_name, emps.group_id, g.color_id, gender, g.name,
                    office_name, jt.name, rank_id, role_name, emps.external_id, email')

    nodes = nodes.as_json
    invmode = CompanyConfigurationTable.is_investigation_mode?
    nodes = nodes.map do |n|
      n['id'] = Employee.external_id_to_id_in_snapshot(n['external_id'].to_s, sid).to_i
      n['t'] = "#{n['first_name']} #{n['last_name']}" if !invmode
      n['t'] = "#{n['id']}_#{n['email']}" if invmode
      n['d'] = n['d'].nil? ? 0 : n['d'].round(2).to_s
      n['group_name'] = n['name']
      n
    end
    return nodes
  end

  ## Aggregate connections among emplyees
  def get_employee_links_for_map(empids, snapshot_field, interval, sid)

    extids = Employee.where(id: empids).pluck(:external_id)
    links = NetworkSnapshotData
            .select('femps.external_id AS source, temps.external_id AS target,
                     count(*) AS w')
            .joins('JOIN employees AS femps ON femps.id = from_employee_id')
            .joins('JOIN employees AS temps ON temps.id = to_employee_id')
            .joins('JOIN snapshots AS sn ON sn.id = network_snapshot_data.snapshot_id')
            .where("sn.%s = '%s'", snapshot_field, interval)
            .where("femps.external_id IN ('#{extids.join("','")}')")
            .where("temps.external_id IN ('#{extids.join("','")}')")
            .group('source, target')

    links = links.map do |l|
      {
        id1: Employee.external_id_to_id_in_snapshot(l['source'].to_s, sid).to_i,
        id2: Employee.external_id_to_id_in_snapshot(l['target'].to_s, sid).to_i,
        w:   l['w'],
        id: nil
      }
    end
    return links
  end
  ################################################################################

  def format_snapshot(p, i)
    {
      to_emp_id: p['employee_to_id'].to_i,
      from_emp_id: p['employee_from_id'].to_i,
      weight: @weight_arr[i]
    }
  end

  def weight_algorithm(snapshot_list, normalize = true)
    weight_arr = []
    if !snapshot_list.empty?
      max_weight = snapshot_list.first['nsum'].to_i
      min_weight = snapshot_list.last['nsum'].to_i
      weight_arr = snapshot_list.collect { |connection| connection['nsum'].to_i }
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
      email_snapshot_data_row.above_median = if email_snapshot_data_row.size >= median
                                               :above
                                             else
                                               :below
                                             end
      email_snapshot_data_row.save
    end
  end

  def calculate_significant_field_for_all_the_email_snapshot_data(_snapshot, emails)
    # old_snapshots = try_to_get_12_snapshots_before(snapshot)
    # company = Snapshot.find(snapshot).company_id
    # network = NetworkSnapshotData.emails(company)
    # num_of_above_arr = NetworkSnapshotData.where(snapshot_id: old_snapshots.map(&:id), network_id: network, above_median: 1)
    # .group(:from_employee_id, :to_employee_id)
    # .count
    # old_snapshots_count = old_snapshots.count
    emails.each do |email|
      # meaningfull_ratio = above_median_ratio(old_snapshots_count, email, num_of_above_arr)
      email.significant_level = :meaningfull
      # email.significant_level = :sporadic        if meaningfull_ratio < 0.6
      # email.significant_level = :not_significant if meaningfull_ratio == 0.0
      email.save!
    end
  end

  def try_to_get_12_snapshots_before(snapshot)
    old_snapshots = []
    tmp_snapshot = snapshot
    (0..11).each do |_time|
      old_snapshots.push(tmp_snapshot)
      break if tmp_snapshot == tmp_snapshot.get_the_snapshot_before_this
      tmp_snapshot = tmp_snapshot.get_the_snapshot_before_this
    end
    return old_snapshots
  end

  def above_median_ratio(old_snapshots_count, email, num_of_above_arr)
    return 1.0 if old_snapshots_count <= 3 && email.above_median == 'above'
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
      (0..num_of_mean_add_to_arr).each { |_i| weight_list << m }
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
        raise 'create_weight_to_netowrk_node - Error: problem in calculate the weight'
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
          puts 'Calculate median'
          calculate_median_field_for_all_the_email_snapshot_data(median, emails)
          puts 'Calculate significant email traffic'
          calculate_significant_field_for_all_the_email_snapshot_data(snapshot, emails)
        end
      end
    else
      # snapshot = Snapshot.find(sid)
      # emails = NetworkSnapshotData.where(snapshot_id: snapshot.id, network_id: network)
      # snapshot_emails_sizes = calc_snapshot_email_traffic_array(emails)
      # median = array_median(snapshot_emails_sizes)
      # puts "median: #{median}"
      puts 'Calculate median field for all email relations'
      # calculate_median_field_for_all_the_email_snapshot_data(median, emails)
      puts 'Calculate significant email traffic'
      # calculate_significant_field_for_all_the_email_snapshot_data(snapshot, emails)
    end
  end
end
