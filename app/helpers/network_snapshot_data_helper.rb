# module NetworkSnapshotNodesHelper
module NetworkSnapshotDataHelper

  NO_SNAPSHOT = -1

  def get_dynamics_map_from_helper(cid, group_name, interval)
    puts "**************"
    puts "in the helper now"
    puts "**************"
    snapshot_field = Snapshot.field_from_interval(interval)
    last_sid = Snapshot.last_snapshot_in_interval(interval, snapshot_field)
    group = Group.where(name: group_name, snapshot_id: last_sid).last
    empids = group.extract_employees
    max_emps = CompanyConfigurationTable.max_emps_in_map

    result_type = 'groups'
    nodes = nil
    links = nil

    if (empids.length > max_emps)
      raise 'groups result not implemented yet'
    else
      result_type = 'emps'

      nodes = Employee
              .select("emps.id, first_name || ' ' || last_name as name,
                       g.name as group_name, g.id as group_id, col.rgb as emp_col")
              .from("employees as emps")
              .joins("join groups as g on g.id = emps.group_id")
              .joins("join colors as col on col.id = g.color_id")
              .where("emps.snapshot_id = ?", last_sid)
              .where("emps.id in (#{empids.join(',')})")

      links = NetworkSnapshotData
              .select('from_employee_id as source, to_employee_id as target')
              .where(snapshot_id: last_sid)
              .where(from_employee_id: empids)
              .where(to_employee_id: empids)
              .distinct
    end

    ret = {
      nodes: nodes,
      links: links,
      result_type: result_type
    }.as_json

    return ret
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
