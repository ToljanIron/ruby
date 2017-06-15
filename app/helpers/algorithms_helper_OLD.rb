# frozen_string_literal: true
#############################################################
# - Variables begining with v_ are hash vectors (arrays of hashes) - [{id: 13, score: 0.4}, {id: 8, score: 1.1}, ...]
# - Variables begining with a_ are scalar arrays - [1,2,3,...]
# - Variables begining with s_ are scalares
# - Variables begining with h_ are hashes: {"1": 0.9, "22": 1.1,  ... }
# - When adding a flag algorithm, add similar algorithm for explore; naming convention: <flag_alg_name>_explore
#############################################################

require './app/helpers/groups_helper.rb'
require './app/helpers/util_helper.rb'
require './app/helpers/selection_helper.rb'
require './app/helpers/cds_dfs_helper.rb'

module AlgorithmsHelper
  NO_PIN     ||= -1
  NO_GROUP   ||= -1
  NO_NETWORK ||= -1

  ID      ||= 0
  MEASURE ||= 1

  NETWORK_OUT ||= 'from_employee_id'
  NETWORK_IN  ||= 'to_employee_id'

  EMAILS_OUT ||= 'from_employee_id'
  EMAILS_IN  ||= 'to_employee_id'

  TO_MATRIX  ||= 1
  CC_MATRIX  ||= 2
  BCC_MATRIX ||= 3
  ALL_MATRIX ||= 4

  BOSS         ||= 10
  ADVICEE_BOSS ||= 11

  Q1 ||= 1
  Q3 ||= 4

  ################################################################################
  ## Quartile calculations for number arrays
  ## Typically used for gauges
  ################################################################################
  def self.find_q1_max(arr)
    raise 'Nil argument' if arr.nil?
    raise 'empty argument' if arr.empty?
    arr = arr.sort
    len = arr.count
    return arr[0] if len == 1 || len == 2
    return arr[1] if len == 3 || len == 4

    q_size = (arr.count % 4 == 0) ? (arr.count / 4) : ((arr.count / 4) + 1)
    return arr[q_size - 1]
  end

  def self.find_q3_min(arr)
    raise 'Nil argument' if arr.nil?
    raise 'empty argument' if arr.empty?
    arr = arr.sort
    len = arr.count
    return arr[arr.count - 1] if len == 1 || len == 2
    return arr[arr.count - 2] if len == 3 || len == 4

    q_size = (arr.count % 4 == 0) ? (arr.count / 4) : ((arr.count / 4) + 1)
    q_size *= -1
    return arr[q_size]
  end

  ################################################################################
  ## Accept:
  ##  - A hash that either looks like this:{"1"=>0.0, "2"=>0.0, "5"=>0.0} Where the
  ##     keys are emplyee IDs.
  ##     or like this: [{id: 1, measure: 0.0}, {id: 2, measure: 0.0} ... ]
  ##  - Array of employee IDs
  ##  - Q1 or Q3 meaning which queartile should be returned
  ##  - Padding value
  ##
  ## It will pad the input hash with missing employees with the the given padding
  ## and returns an array of meployee iDs of the high or low queartile
  ################################################################################
  def self.slice_percentile_from_hash_array(scores, s_order = Q3, a_emps = [], s_pad = 0, percentile = 4)
    return [] if scores.nil?
    return [] if scores.length <= percentile
    raise "Illegal argument, 4th argument's value should be 1 or 3" if s_order != Q1 && s_order != Q3

    ## This function works with two types of data structures for the scores parameter:
    ##   [{id: i, measure: measure} ... ]
    ## as well as:
    ##   {"id1": measure1, "id2": measure2, ... }
    ## So if needed will convert to the array of hash format
    v_scores = []
    if scores.class == Hash
      scores.each { |k, v| v_scores << { id: k.to_s, measure: v } }
    else
      v_scores = scores
    end

    ## In some cases we don't have scores for all of the employees in the group, so
    ## will be padding with zeros by default.
    a_emps.each do |emp|
      v_scores << { id: emp.to_s, measure: s_pad } if scores[emp.to_s].nil?
    end

    ## Do not count on calling function to sort
    v_scores = v_scores.sort_by { |h| [h[:measure], h[:id]] }
    v_scores = v_scores.reverse! if s_order == Q3

    limit = (v_scores.count / percentile)
    limit += 1 if v_scores.count % percentile != 0

    ## This is inteded to avoid messing up flat distributions
    ## A flat distribution in this context meanse a v_scores of the follwing type:
    ##   [1,2,2,2,2,4,8,20] - In this example we have an array of length 8. so
    ## strictly speaking the bottom quartile should have been [1,2], but since
    ## 2 takes up so much values from the v_scores we do not want to include it.
    bound = v_scores[limit.to_i][:measure]
    result = []
    (0..(limit.to_i - 1)).each do |emp|
      result.push(v_scores[emp]) if v_scores[emp][:measure] < bound && s_order == Q1
      result.push(v_scores[emp]) if v_scores[emp][:measure] > bound && s_order == Q3
    end
    return result
  end

  def self.to_ids_array(arr)
    return [] if arr.nil?
    return arr.map { |e| e[:id].to_i }
  end

  def self.harsh_idscore_to_upperlower_quartile_emp_ids(h_scores, a_emps, _s_order = Q3, s_pad = 0)
    v_scores = []
    a_emps.each do |emp|
      score = h_scores[emp.to_s].nil? ? s_pad : h_scores[emp.to_s]
      v_scores << { id: emp, score: score }
    end
    v_scores = v_scores.sort_by { |h| [h[:score], h[:id]] }
    v_scores_arr = json_to_array_score(v_scores)
    q1 = find_q1_max(v_scores_arr)
    q3 = find_q3_min(v_scores_arr)
    iqr = q3 - q1
    limit = q3 + iqr * 1.5
    result = []
    v_scores.each do |score|
      result.push(score) if score[:score] > limit
    end
    result
  end

  def self.get_company_id(snapshot_id)
    company_id = Snapshot.where('id = ?', snapshot_id).first.company_id unless Snapshot.where('id = ?', snapshot_id).empty?
    return company_id
  end

  def self.no_of_emails_sent(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.where(id: snapshot_id).first.company_id
    emps = get_members_in_group(pid, gid, cid)
    network = NetworkSnapshotData.emails(cid)
    sqlstr = "SELECT from_employee_id, COUNT(DISTINCT(message_id)) AS emails_sum 
              FROM network_snapshot_data 
              WHERE from_employee_id IN (#{emps.join(',')}) 
              AND snapshot_id           = #{snapshot_id} 
              AND network_id            = #{network} 
              GROUP BY from_employee_id"
    sent_emails = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    array_of_values, limit = find_limit(sent_emails)
    counter = 0
    array_of_values.each do |number|
      counter += 1 if number > limit
    end
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: counter.to_f / emps.count.to_f }] if emps.count.to_f != 0
    return [{ group_id: group_id, measure: 0.to_f }]
  end

  def self.no_of_emails_sent_for_explore(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.where(id: snapshot_id).first.company_id
    emps = get_members_in_group(pid, gid, cid)
    network = NetworkSnapshotData.emails(cid)
    sqlstr = "SELECT from_employee_id, COUNT(DISTINCT(message_id)) AS emails_sum 
              FROM network_snapshot_data 
              WHERE from_employee_id IN (#{emps.join(',')}) 
              AND snapshot_id           = #{snapshot_id} 
              AND network_id            = #{network} 
              GROUP BY from_employee_id"
    sent_emails = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    _array_of_values, limit = find_limit(sent_emails)
    explore_grd = {}
    emps.each do |emp|
      explore_grd[emp.to_i] = 0
    end
    sent_emails.each do |emp|
      explore_grd[emp['from_employee_id'].to_i] = 1 if emp['emails_sum'].to_i > limit
    end
    grades = []
    explore_grd.each do |grade|
      grades.push(id: grade[0], measure: grade[1])
    end
    return grades
  end

  def self.no_of_emails_received(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.where(id: snapshot_id).first.company_id
    emps = get_members_in_group(pid, gid, cid)
    network = NetworkSnapshotData.emails(cid)
    sqlstr = "SELECT to_employee_id, COUNT(DISTINCT(message_id)) AS emails_sum 
              FROM network_snapshot_data 
              WHERE to_employee_id IN (#{emps.join(',')}) 
              AND snapshot_id         = #{snapshot_id} 
              AND network_id          = #{network} 
              GROUP BY to_employee_id"
    sent_emails = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    array_of_values, limit = find_limit(sent_emails)
    counter = 0
    array_of_values.each do |number|
      counter += 1 if number > limit
    end
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: counter.to_f / emps.count.to_f }] if emps.count.to_f != 0
    return [{ group_id: group_id, measure: 0.to_f }]
  end

  def self.no_of_emails_received_for_explore(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.where(id: snapshot_id).first.company_id
    emps = get_members_in_group(pid, gid, cid)
    network = NetworkSnapshotData.emails(cid)
    sqlstr = "SELECT to_employee_id, COUNT(DISTINCT(message_id)) AS emails_sum
              FROM network_snapshot_data
              WHERE to_employee_id IN (#{emps.join(',')})
              AND snapshot_id         = #{snapshot_id}
              AND network_id          = #{network}
              GROUP BY to_employee_id"
    sent_emails = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    _array_of_values, limit = find_limit(sent_emails)
    explore_grd = {}
    emps.each do |emp|
      explore_grd[emp.to_i] = 0
    end
    sent_emails.each do |emp|
      explore_grd[emp['from_employee_id'].to_i] = 1 if emp['emails_sum'].to_i > limit
    end
    grades = []
    explore_grd.each do |grade|
      grades.push(id: grade[0], measure: grade[1])
    end
    return grades
  end

# Gets a snapshot and a group number, returns the average number of attendees from said group in meetings related to it
  def self .average_no_of_attendees(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.where(id: snapshot_id).first.company_id
    emps = get_members_in_group(pid, gid, cid)
    groups = get_group_and_all_its_descendants(gid)
    groups = (groups.length == 0 ? get_group_and_all_its_descendants(Group::get_root_group(cid)) : groups)
    sqlstrdenom =  "SELECT COUNT(DISTINCT meeting_id) AS count
                    FROM meetings           AS mee
                    JOIN meeting_attendees  AS mee_att    ON mee_att.meeting_id = mee.id
                    JOIN employees          AS emp        ON emp.id             = mee_att.attendee_id
                    WHERE emp.group_id IN   (#{groups.join(',')})
                    AND   mee.snapshot_id   =#{snapshot_id}"
    denominator = ActiveRecord::Base.connection.select_all(sqlstrdenom).to_hash
    denominator = denominator[0]["count"].to_f
    return [{ group_id: gid, measure: 0.to_f }] if denominator == 0
    sqlstrnumer =  "SELECT COUNT((#{emps.join(',')})) AS count
                    FROM meeting_attendees  AS mee_att
                    JOIN meetings           AS mee    ON mee_att.meeting_id = mee.id
                    JOIN employees          AS emp    ON emp.id             = mee_att.attendee_id
                    WHERE emp.group_id IN   (#{groups.join(',')})
                    AND   mee.snapshot_id   =#{snapshot_id}"
    numerator = ActiveRecord::Base.connection.select_all(sqlstrnumer).to_hash
    numerator = numerator[0]["count"].to_f
    return [{ group_id: gid, measure: (numerator/denominator).to_f}]
  end

# Gets a snapshot and a group number, returns the time spent in meetings in proportion of the group's size
  def self .proportion_time_spent_on_meetings(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.where(id: snapshot_id).first.company_id
    emps = get_members_in_group(pid, gid, cid)
    groups = get_group_and_all_its_descendants(gid)
    groups = (groups.length == 0 ? get_group_and_all_its_descendants(Group::get_root_group(cid)) : groups)
    weekly_hours = 50
    sqlstrnumer = "SELECT SUM(duration_in_minutes) AS sum
                  FROM meetings as mee
                  JOIN meeting_attendees  AS mee_att  ON mee_att.meeting_id = mee.id
                  JOIN employees          AS emp      ON emp.id             = mee_att.attendee_id
                  WHERE emp.group_id IN (#{groups.join(',')})
                  AND   snapshot_id     =#{snapshot_id}"
    numerator = ActiveRecord::Base.connection.select_all(sqlstrnumer).to_hash
    numerator = numerator[0]["sum"].to_f
    return [{ group_id: gid, measure: 0.to_f }] if numerator == 0
    denominator = ((emps.length)*weekly_hours*60).to_f
    return [{ group_id: gid, measure: (numerator/denominator).to_f}]  if denominator > numerator
    return [{ group_id: gid, measure: 1.to_f}]
  end

  def self.proportion_of_managers_never_in_meetings(sid, pid = NO_PIN, gid = NO_GROUP)
    company = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, company)
    group_id = Group.find(gid)
    managers = group_id.get_managers[:manager_id].count.to_f
    return [{ group_id: gid, measure: 0 }] if is_less_than_100_emps(emps) || managers == 0
    numerator = manager_never_in_meetings_flag(sid, pid, gid).count.to_f
    return [{ group_id: gid, measure: numerator / managers }]
  end

  def self.is_less_than_100_emps(emps)
    return (emps.count.to_f < 100)
  end

  def manager_never_in_meetings_flag(sid, pid, gid)
    res = read_or_calculate_and_write("manager_never_in_meetings_flag-#{sid}-#{pid}-#{gid}") do
      # cid = find_company_by_snapshot(sid)
      group = Group.find(gid)
      inner_select = group.get_managers
      weeklyWorkHours = 50
      sqlstr =  "SELECT SUM(duration_in_minutes) AS sum, emp.id AS id 
                FROM meetings           AS mee
                JOIN meeting_attendees  AS mee_att  ON mee_att.meeting_id = mee.id
                JOIN employees          AS emp      ON emp.id             = mee_att.attendee_id
                WHERE emp.id    IN  (#{inner_select[:manager_id].join(',')}) 
                AND snapshot_id     =#{sid}
                GROUP BY emp.id"
      res = ActiveRecord::Base.connection.exec_query(sqlstr)
      h_scores = {}
      res.each do |r|
        h_scores[r['id']] = 1-((r['sum'].to_f)/(60*weeklyWorkHours))
      end
      a = h_scores.sort_by {|h| [h[1]]}.reverse!
      limit = (a.count / 4)
      limit += 1 if (a.count-1) % 4 != 0
      bound = a[limit.to_i][1]
      res = AlgorithmsHelper.harsh_idscore_to_upperlower_quartile_emp_ids(h_scores, inner_select[:manager_id])
      res.each do |e|
         e[:measure] = e[:score] unless e[:measure] == bound
        end
      return res
    end
    return res
  end

  def self.find_limit(sent_emails)
    array_of_values = json_to_array_sinks(sent_emails)
    return array_of_values, 0 if array_of_values.empty?
    q1 = find_q1_max array_of_values
    q3 = find_q3_min array_of_values
    iqr = q3 - q1
    return array_of_values, q3 + iqr * 1.5
  end

  def self.calculate_internal_faultlines(snapshot_id, network_id, network_id_1, network_id_2, pid = NO_PIN, gid = NO_GROUP, rubrica)
    grade_for_network = []
    grade_for_network.push(calculate_internal_faultlines_for_network(snapshot_id, network_id, pid, gid, rubrica))
    grade_for_network.push(calculate_internal_faultlines_for_network(snapshot_id, network_id_1, pid, gid, rubrica))
    grade_for_network.push(calculate_internal_faultlines_for_emails(snapshot_id, pid, gid, rubrica))
    grade_for_network.push(calculate_internal_faultlines_for_network(snapshot_id, network_id_2, pid, gid, rubrica))
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: calc_average_internal(grade_for_network) }]
  end

  def self.calculate_external_faultlines(snapshot_id, network_id, network_id_1, network_id_2, pid = NO_PIN, gid = NO_GROUP)
    v_grade_for_network = []
    v_grade_for_network.push(calculate_external_faultlines_for_network(snapshot_id, network_id, pid, gid))
    v_grade_for_network.push(calculate_external_faultlines_for_network(snapshot_id, network_id_1, pid, gid))
    v_grade_for_network.push(calculate_external_faultlines_for_emails(snapshot_id, pid, gid))
    v_grade_for_network.push(calculate_external_faultlines_for_network(snapshot_id, network_id_2, pid, gid))
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: calc_average_internal(v_grade_for_network) }]
  end

  def calc_average_internal(grade_for_network)
    grade = 0
    grade_for_network.each do |grd|
      grade += grd
    # id: grade[0], measure: grade[1]
    end
    grade /= 4
    return grade
  end

  # def get_all_pos_couples(emps)   #DEAD CODE
  #   res = []
  #   emps.each do |emp|
  #     emps.each do |em1|
  #       res.push([emp, em1]) if emp != em1
  #     end
  #   end
  #   return res
  # end

  # def value_of_email(email)   #DEAD CODE
  #   email = EmailSnapshotData.where(from_employee_id: from, to_employee_id: to, snapshot_id: snapshot_id).first
  #   return email.n1 + email.n2 + email.n3 + email.n4 + email.n5 + email.n6 + email.n7 + email.n8 + email.n9 + email.n10 + email.n11 + email.n12 + email.n13 + email.n14 + email.n15 + email.n16 + email.n17 + email.n18
  # end

  # def self.calculate_network_distance(avg, network_connection)   #DEAD CODE
  #   return (0 - avg[0]) if network_connection.nil?
  #   return network_connection.value - avg[0]
  # end

  # def self.calculate_emails_distance(avg, email_connection)   #DEAD CODE
  #   email_connection = EmailSnapshotData.where(from_employee_id: grp[0], to_employee_id: grp[1], snapshot_id: snapshot_id).first
  #   return (0 - avg[1]) if email_connection.nil?
  #   return value_of_email(email_connection) - avg[1]
  # end

  # def self.calculate_network_dstrbte(avg, network_connection)  #DEAD CODE
  #   return ((0 - avg[0]) * (0 - avg[0])) if network_connection.nil?
  #   return (network_connection.value - avg[0]) * (network_connection.value - avg[0])
  # end

  # def self.calculate_emails_dstrbte(avg, email_connection)    #DEAD CODE
  #   email_connection = EmailSnapshotData.where(from_employee_id: grp[0], to_employee_id: grp[1], snapshot_id: snapshot_id).first
  #   return (0 - avg[1]) * (0 - avg[1]) if email_connection.nil?
  #   email_val = value_of_email(email_connection) - avg[1]
  #   return email_val * email_val
  # end

  def self.calculate_embeddednes_of_emails_and_networks(snapshot_id, network_id, network_b_id, network_c_id, pid = NO_PIN, gid = NO_GROUP)
    first_cor = calculate_embeddednes_emails_networks(snapshot_id, network_id, pid, gid)
    sec_cor = calculate_embeddednes_emails_networks(snapshot_id, network_b_id, pid, gid)
    third_cor = calculate_embeddednes_emails_networks(snapshot_id, network_c_id, pid, gid)
    return [{ group_id: third_cor[0][:group_id], measure: (third_cor[0][:measure] + sec_cor[0][:measure] + first_cor[0][:measure]).to_f / 3.to_f }]
  end

  def self.calculate_embeddednes_emails_networks(snapshot_id, _network_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.where(id: snapshot_id).first.company_id
    emps = get_members_in_group(pid, gid, cid)
    sqlstr = "select (CAST(sum(n1+n2+n3+n4+n5+n6+n7+n8+n9+n10+n11+n12+n13+n14+n15+n16+n17+n18) AS float))/(CAST(#{emps.count}*(#{emps.count}-1) AS float)) as emails_sum from email_snapshot_data
             where snapshot_id= #{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id and significant_level = 3"
    sum = ActiveRecord::Base.connection.select_all(sqlstr)[0].to_hash
    email_average = sum['emails_sum'].to_f
    sqlstr = "select (CAST(sum(value) AS float)/(CAST(#{emps.count}*(#{emps.count}-1) AS float))) as network_sum from network_snapshot_data
             where snapshot_id= #{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')})"
    sum = ActiveRecord::Base.connection.select_all(sqlstr)[0].to_hash
    network_average = sum['network_sum'].to_f
    sqlstr = "select CAST(sum(((CAST((n1+n2+n3+n4+n5+n6+n7+n8+n9+n10+n11+n12+n13+n14+n15+n16+n17+n18) AS float))-CAST(#{email_average} AS float)))*((cast(value as float))-cast(#{network_average} as float)) as float) as pearson from email_snapshot_data as em inner join network_snapshot_data as network on em.to_employee_id=network.to_employee_id and em.from_employee_id=network.from_employee_id
             where network.snapshot_id= #{snapshot_id} and em.snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) group by value"
    sum_of_joint = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    sum_of_joint = if !sum_of_joint.nil? && !sum_of_joint[0].nil?
                     sum_of_joint[0]['pearson'].to_f
                   else
                     0
                   end
    # sqlstr = "select to_employee_id,from_employee_id from email_snapshot_data where snapshot_id= #{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')})"
    # sum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    sqlstr = "select sum((cast((0-#{email_average}) as float))*(cast(0-#{network_average} as float))) as pearson from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id) and not exists (select 1 from network_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
    complementary = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    complementary_no_emails_no_network = 0 if complementary.nil? || complementary[0].nil?
    complementary_no_emails_no_network = complementary[0]['pearson'].to_f if !complementary.nil? && !complementary[0].nil?
    # this complements cases where network is and email is not
    sqlstr = "select sum((cast((0-#{email_average}) as float))*(cast(value-#{network_average} as float))) as network_complement from network_snapshot_data where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where to_employee_id=to_employee_id and significant_level = 3 and from_employee_id=from_employee_id)"
    complementary = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    complementary_no_emails_yes_network = complementary[0]['network_complement'].to_f if !complementary.nil? && !complementary[0].nil?
    complementary_no_emails_yes_network = 0 if complementary.nil? || complementary[0].nil?
    # this complements cases where email exists and network does not
    sqlstr = "select sum(cast(((n1+n2+n3+n4+n5+n6+n7+n8+n9+n10+n11+n12+n13+n14+n15+n16+n17+n18)-#{email_average}) as float)*(cast((0-#{network_average}) as float))) as email_complement from email_snapshot_data where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and not exists (select 1 from network_snapshot_data where to_employee_id=to_employee_id and from_employee_id=from_employee_id)"
    complementary = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    complementary_no_network_yes_emails = complementary[0]['email_complement'].to_f if !complementary.nil? && !complementary[0].nil?
    complementary_no_network_yes_emails = 0 if complementary.nil? || complementary[0].nil?
    sqlstr = "select sum(power(cast(((n1+n2+n3+n4+n5+n6+n7+n8+n9+n10+n11+n12+n13+n14+n15+n16+n17+n18)-#{email_average}) as float),2)) as pearson from email_snapshot_data
             where significant_level = 3 and snapshot_id= #{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')})"
    denominatore = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    denominator = denominatore[0]['pearson'].to_f if !denominatore.nil? && !denominatore[0].nil?
    denominator = 0 if denominatore.nil? || denominatore[0].nil?
    sqlstr = "select sum(power((cast((0-#{email_average}) as float)),2)) as pearson from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
    complementary_email_denominatore = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    complementary_email_denominator = complementary_email_denominatore[0]['pearson'].to_f if !complementary_email_denominatore.nil? && !complementary_email_denominatore[0].nil?
    complementary_email_denominator = 0 if complementary_email_denominatore.nil? || complementary_email_denominatore[0].nil?
    sqlstr = "select sum(power(cast((value-#{network_average}) as float),2)) as pearson from network_snapshot_data
             where snapshot_id= #{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')})"
    network_denominatore = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    network_denominator = network_denominatore[0]['pearson'].to_f if !network_denominatore.nil? && !network_denominatore[0].nil?
    network_denominator = 0 if network_denominatore.nil? || network_denominatore[0].nil?
    sqlstr = "select sum(power((cast((0-#{network_average}) as float)),2)) as pearson from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from network_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
    complementary_network_denominatore = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    complementary_network_denominator = complementary_network_denominatore[0]['pearson'].to_f if !complementary_network_denominatore.nil? && !complementary_network_denominatore[0].nil?
    complementary_network_denominator = 0 if complementary_network_denominatore.nil? || complementary_network_denominatore[0].nil?
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: 0 }] if Math.sqrt((denominator + complementary_email_denominator) * (network_denominator + complementary_network_denominator)) == 0
    result = (sum_of_joint + complementary_no_emails_no_network + complementary_no_emails_yes_network + complementary_no_network_yes_emails) / Math.sqrt((denominator + complementary_email_denominator) * (network_denominator + complementary_network_denominator))
    return [{ group_id: group_id, measure: result.round(3) }]
  end

  def self.list_to_hash(list)
    hash = {}
    list.each do |emp|
      hash[emp['from_employee_id'].to_i] = emp['emails_sum'].to_i
    end
    hash
  end

  def self.json_to_array(json_obj)
    res = []
    json_obj.each do |obj|
      res.push(obj[:email_ratio].to_f)
    end
    return res
  end

  def self.json_to_array_score(json_obj)
    res = []
    json_obj.each do |obj|
      res.push(obj[:score].to_f)
    end
    return res
  end

  def self.json_to_array_sinks(json_obj)
    res = []
    json_obj.each do |obj|
      res.push(obj['emails_sum'].to_f)
    end
    return res
  end

  def self.find_bottlenecks(arr, limit)
    res = []
    arr.each do |obj|
      res.push(obj) if obj[:email_ratio].to_f > limit
    end
    return res
  end

  def self.return_ns
    return 'n1+n2+n3+n4+n5+n6+n7+n8+n9+n10+n11+n12+n13+n14+n15+n16+n17+n18'
  end

  def self.do_log(list, hashtable, _strate_infimum)
    new_list = []
    list.each do |li|
      # new_list.push({"candidate": li, "email_ratio": (hashtable[li.to_s].to_f != 0.to_f ? Math.log(hashtable[li.to_s].to_f).round(3) : 0)})
      new_list.push("candidate": li, "email_ratio": (hashtable[li.to_s].to_f != 0.to_f ? hashtable[li.to_s].to_f.round(3) : 0))
    end
    new_list
  end

  def self.json_to_hash_table(arr)
    json_to_return = {}
    arr.each do |object|
      json_to_return[object['from_employee_id'] + '_' + object['to_employee_id']] = object['emails_sum'].to_f
    end
    json_to_return
  end

  def self.emps_without_managers(emps)
    new_emps = []
    emps.each do |em|
      new_emps.push(em.to_s)
    end
    new_emps
  end

  def self.calculate_inner_ratios_for_bottlenecks(ingroupgrades, outgroupgrades, emps, strate_infimum)
    candidates = {}
    ingroupgrades = json_to_hash_table(ingroupgrades)
    outgroupgrades = json_to_hash_table(outgroupgrades)
    str_emps = emps_without_managers(emps)
    str_emps.each do |candidate|
      str_emps.each do |from|
        str_emps.each do |to|
          next if from == to || candidate == from || candidate == to
          candidates[candidate] = 0.to_f if candidates[candidate].nil?
          candidates[candidate] += ingroupgrades[from + '_' + candidate] * outgroupgrades[candidate + '_' + to] / outgroupgrades[from + '_' + to] if outgroupgrades[from + '_' + to] != 0
          candidates[candidate] += ingroupgrades[from + '_' + candidate] * outgroupgrades[candidate + '_' + to] / strate_infimum.to_f if outgroupgrades[from + '_' + to] == 0
        end
      end
    end
    return candidates
  end

  def self.json_to_array_for_subject(json_obj)
    res = []
    json_obj.each do |obj|
      res.push(obj['subject_length'].to_f)
    end
    return res
  end

  def self.find_subjects(arr, limit)
    res = []
    arr.each do |obj|
      res.push(obj) if obj['subject_length'].to_f > limit
    end
    return res
  end

  def self.avg_subject_length(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid)

    group_id = (gid == -1 ? pid : gid)
    length_str = is_sql_server_connection? ? 'LEN' : 'LENGTH'

    sqlstr = "select employee_from_id, sum(#{length_str}(subject)) as subject_length from email_subject_snapshot_data where employee_from_id in (#{emps.join(',')}) group by employee_from_id"

    subjects = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    array_of_subject_length = json_to_array_for_subject subjects
    return [{ group_id: group_id, measure: 0 }] if emps.count < 3 || array_of_subject_length.empty?
    q4 = find_q3_min(array_of_subject_length)
    iqr = q4 - find_q1_max(array_of_subject_length)
    limit = q4 + (iqr * 1.5)
    result = find_subjects(subjects, limit)
    return [{ group_id: group_id, measure: result.count.to_f / emps.count.to_f }]
  end

  def new_explore_for_gauge(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid)
    result = []
    emps.each do |emp|
      result.push(id: emp.to_i, measure: 1)
    end
    result
  end

  def self.calculate_gate_keepers(snapshot_id, pid = NO_PIN, gid = NO_GROUP, sql_server = false)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid)
    out_emps = get_members_not_in_group(emps, cid)
    group_id = (gid == -1 ? pid : gid)
    candidates = {}
    strate_infimum = 1
    if sql_server
      return [{ group_id: group_id, measure: 0 }] if emps.count < 3
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id      )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id        )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)) as t1 order by t1.emails_sum asc"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      infimum.each do |inf|
        infimum.delete(inf) if inf['emails_sum'] == '0' || inf['emails_sum'] == 0.0
      end
      strate_infimum = infimum[0]['emails_sum'] unless infimum.empty?
      # couples query outgrade
      sqlstr = "select from_employee_id, to_employee_id, (case when (cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id           ) as float))<>0 then (cast((#{return_ns})as float)/ cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id           ) as float)) else 0 end) as emails_sum from email_snapshot_data as apsd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id = #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      # couples query  ingrade
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data significant_level = 3 and as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float)else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where significant_level = 3 and snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = find_candidates(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      # ingroupgrades = json_to_hash_table(ingroupgrades)
      # outgroupgrades = json_to_hash_table(outgroupgrades)
      # str_emps = emps_without_managers(emps)
      # str_emps.each do |candidate|
      #   str_emps.each do |from|
      #     str_emps.each do |to|
      #       next if from == to || candidate == from || candidate == to
      #       candidates[candidate] = 0.to_f if candidates[candidate].nil?
      #       candidates[candidate] += outgroupgrades[candidate + '_' + from] * ingroupgrades[candidate + '_' + to] / ingroupgrades[from + '_' + to] if ingroupgrades[from + '_' + to] != 0
      #       candidates[candidate] += outgroupgrades[candidate + '_' + from] * ingroupgrades[candidate + '_' + to] / strate_infimum.to_f if ingroupgrades[from + '_' + to] == 0
      #     end
      #   end
      # end
    else
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1       )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)order by emails_sum) as t1 order by t1.emails_sum asc"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      infimum.each do |inf|
        infimum.delete(inf) if inf['emails_sum'] == '0'
      end
      strate_infimum = 1
      strate_infimum = infimum[0]['emails_sum'] unless infimum.empty?

      # couples query outgrade
      sqlstr = "select from_employee_id, to_employee_id, (case when (cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1          ) as float))<>0 then (cast((#{return_ns})as float)/ cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1          ) as float)) else 0 end) as emails_sum from email_snapshot_data as apsd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      # couples query  ingrade
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float)else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where significant_level = 3 and snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      candidates = {}
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      # all_couples_in_group = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = find_candidates(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      candidates = create_base_line_for_log(emps, candidates)
      # ingroupgrades = json_to_hash_table(ingroupgrades)
      # outgroupgrades = json_to_hash_table(outgroupgrades)
      # str_emps = emps_without_managers(emps)
      # str_emps.each do |candidate|
      #   str_emps.each do |from|
      #     str_emps.each do |to|
      #       next if from == to || candidate == from || candidate == to
      #       candidates[candidate] = 0.to_f if candidates[candidate].nil?
      #       candidates[candidate] += outgroupgrades[candidate + '_' + from] * ingroupgrades[candidate + '_' + to] / ingroupgrades[from + '_' + to] if ingroupgrades[from + '_' + to] != 0
      #       candidates[candidate] += outgroupgrades[candidate + '_' + from] * ingroupgrades[candidate + '_' + to] / strate_infimum.to_f if ingroupgrades[from + '_' + to] == 0
      #     end
      #   end
      # end
    end
    if is_there_zero(emps, candidates)
      emps.each do |candidate|
        candidates[candidate.to_s] += 1
      end
    end

    if is_there_zero(emps, candidates)
      emps.each do |candidate|
        candidates[candidate.to_s] += 1
      end
    end
    all_couples_in_group = do_log(emps, candidates, strate_infimum)
    return [{ group_id: group_id, measure: 0 }] if all_couples_in_group.empty?
    q4 = find_q3_min(json_to_array(all_couples_in_group))
    iqr = q4 - find_q1_max(json_to_array(all_couples_in_group))
    limit = q4 + (iqr * 1.5)
    result = find_bottlenecks(all_couples_in_group, limit)
    return [{ group_id: group_id, measure: result.count.to_f / emps.count.to_f }]
  end

  def self.calculate_gate_keepers_for_flag(snapshot_id, pid = NO_PIN, gid = NO_GROUP, sql_server: false)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid)
    out_emps = get_members_not_in_group(emps, cid)
    result = []
    candidates = {}
    strate_infimum = 1
    if emps.count < 3
      emps.each do |emp|
        result.push(id: emp.to_i, measure: 0)
      end
      return result
    end
    if sql_server
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id        )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)order by emails_sum) as t1 order by t1.emails_sum asc"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      infimum.each do |inf|
        infimum.delete(inf) if inf['emails_sum'] == '0' || inf['emails_sum'] == 0.0
      end
      strate_infimum = infimum[0]['emails_sum'] unless infimum.empty?

      # couples query
      sqlstr = "select first_sender, first_receiver, second_sender, second_receiver, inner_ratio, outer_ratio from (select t1.from_employee_id as first_sender, t1.to_employee_id as first_receiver, t2.from_employee_id as second_sender, t2.to_employee_id as second_receiver, t1.emails_sum as inner_ratio,t2.emails_sum as outer_ratio from (select to_employee_id, from_employee_id, cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id))as t1
      inner join (select from_employee_id, to_employee_id, cast((    #{return_ns})as float)/ cast((       select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id           ) as float) as emails_sum from email_snapshot_data as apsd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)) as t2 on t1.to_employee_id=t2.from_employee_id) as t5 where first_sender<>second_receiver"
      # couples query outgrade
      sqlstr = "select from_employee_id, to_employee_id, (case when (cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id           ) as float))<>0 then (cast((#{return_ns})as float)/ cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id           ) as float)) else 0 end) as emails_sum from email_snapshot_data as apsd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      # couples query  ingrade
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float)else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where significant_level = 3 and snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      all_couples_in_group = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = find_candidates(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      candidates = create_base_line_for_log(emps, candidates)
    else
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1       )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)order by emails_sum) as t1 order by t1.emails_sum asc"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      infimum.each do |inf|
        infimum.delete(inf) if inf['emails_sum'] == '0'
      end
      strate_infimum = 1
      strate_infimum = infimum[0]['emails_sum'] unless infimum.empty?

      # couples query outgrade
      sqlstr = "select from_employee_id, to_employee_id, (case when (cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1          ) as float))<>0 then (cast((#{return_ns})as float)/ cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1          ) as float)) else 0 end) as emails_sum from email_snapshot_data as apsd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      # couples query  ingrade
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float)else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where significant_level = 3 and snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      candidates = {}
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = find_candidates(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      candidates = create_base_line_for_log(emps, candidates)
    end
    all_couples_in_group = do_log(emps, candidates, strate_infimum)
    if all_couples_in_group.empty?
      emps.each do |emp|
        result.push(id: emp.to_i, measure: 0)
      end
      return result
    end
    q4 = find_q3_min(json_to_array(all_couples_in_group))
    iqr = q4 - find_q1_max(json_to_array(all_couples_in_group))
    limit = q4 + (iqr * 1.5)
    result = find_bottlenecks(all_couples_in_group, limit)
    res = []
    id_arr = json_to_id_array_int(result)
    emps.each do |emp|
      if id_arr.include?(emp.to_i)
        res.push(id: emp.to_i, measure: 1)
      else
        res.push(id: emp.to_i, measure: 0)
      end
    end
    return res
  end

  def self.create_base_line_for_log(emps, candidates)
    return candidates unless is_there_zero(emps, candidates)
    emps.each do |candidate|
      candidates[candidate.to_s] += 1
    end
    return candidates
  end

  def self.calculate_gate_keepers_for_flag_explore(snapshot_id, pid = NO_PIN, gid = NO_GROUP, sql_server: false)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid)
    out_emps = get_members_not_in_group(emps, cid)
    result = []
    if emps.count < 3
      emps.each do |emp|
        result.push(id: emp.to_i, measure: 0)
      end
      return result
    end
    candidates = {}
    strate_infimum = 1
    if sql_server
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id        )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)order by emails_sum) as t1 order by t1.emails_sum asc"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      infimum.each do |inf|
        infimum.delete(inf) if inf['emails_sum'] == '0' || inf['emails_sum'] == 0.0
      end
      strate_infimum = infimum[0]['emails_sum'] unless infimum.empty?
      # couples query outgrade
      sqlstr = "select from_employee_id, to_employee_id, (case when (cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id           ) as float))<>0 then (cast((#{return_ns})as float)/ cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id           ) as float)) else 0 end) as emails_sum from email_snapshot_data as apsd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      # couples query  ingrade
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float)else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where significant_level = 3 and snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      all_couples_in_group = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = find_candidates(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      candidates = create_base_line_for_log(emps, candidates)
    else
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1       )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)order by emails_sum) as t1 order by t1.emails_sum asc"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      infimum.each do |inf|
        infimum.delete(inf) if inf['emails_sum'] == '0'
      end
      strate_infimum = 1
      strate_infimum = infimum[0]['emails_sum'] unless infimum.empty?

      # couples query
      sqlstr = "select first_sender, first_receiver, second_sender, second_receiver, inner_ratio, outer_ratio from (select t1.from_employee_id as first_sender, t1.to_employee_id as first_receiver, t2.from_employee_id as second_sender, t2.to_employee_id as second_receiver, t1.emails_sum as inner_ratio,t2.emails_sum as outer_ratio from (select to_employee_id, from_employee_id, cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id))as t1
      inner join (select from_employee_id, to_employee_id, cast((    #{return_ns})as float)/ cast((       select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1          ) as float) as emails_sum from email_snapshot_data as apsd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id =  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)) as t2 on t1.to_employee_id=t2.from_employee_id) as t5 where first_sender<>second_receiver"

      # couples query outgrade
      sqlstr = "select from_employee_id, to_employee_id, (case when (cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1          ) as float))<>0 then (cast((#{return_ns})as float)/ cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1          ) as float)) else 0 end) as emails_sum from email_snapshot_data as apsd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      # couples query  ingrade
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float)else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where significant_level = 3 and snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      candidates = {}
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      all_couples_in_group = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = find_candidates(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      candidates = create_base_line_for_log(emps, candidates)
    end
    all_couples_in_group = do_log(emps, candidates, strate_infimum)
    if all_couples_in_group.empty?
      emps.each do |emp|
        result.push(id: emp.to_i, measure: 0)
      end
      return result
    end
    q4 = find_q3_min(json_to_array(all_couples_in_group))
    iqr = q4 - find_q1_max(json_to_array(all_couples_in_group))
    limit = q4 + (iqr * 1.5)
    result = find_bottlenecks(all_couples_in_group, limit)
    res = []
    id_arr = json_to_id_array_int(result)
    emps.each do |emp|
      if id_arr.include?(emp.to_i)
        res.push(id: emp.to_i, measure: 10)
      else
        res.push(id: emp.to_i, measure: 0)
      end
    end
    return res
  end

  def self.emps_to_array(out_emps)
    out_emps_str = []
    out_emps.each do |emp|
      out_emps_str.push emp.to_s
    end
    out_emps_str
  end

  def self.find_candidates(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
    candidates = {}
    ingroupgrades = json_to_hash_table(ingroupgrades)
    outgroupgrades = json_to_hash_table(outgroupgrades)
    str_emps = emps_without_managers(emps)
    out_emps = emps_to_array(out_emps)
    str_emps.each do |candidate|
      str_emps.each do |from|
        out_emps.each do |to|
          next if from == to || candidate == from || candidate == to
          candidates[candidate] = 0.to_f if candidates[candidate].nil?
          out_cand_from = outgroupgrades[candidate + '_' + from]
          in_cand_to    = ingroupgrades[candidate + '_' + to]
          in_from_to    = ingroupgrades[from + '_' + to]
          candidates[candidate] += out_cand_from * in_cand_to / in_from_to          if in_from_to != 0 && !in_from_to.nil?
          candidates[candidate] += out_cand_from * in_cand_to / strate_infimum.to_f if in_from_to == 0 && !in_from_to.nil?
        end
      end
    end
    return candidates
  end

  def self.calculate_gate_keepers_for_explore(snapshot_id, pid = NO_PIN, gid = NO_GROUP, sql_server: false)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid)
    out_emps = get_members_not_in_group(emps, cid)
    result = []
    if emps.count < 3
      emps.each do |emp|
        result.push(id: emp.to_i, measure: 0)
      end
      return result
    end
    candidates = {}
    strate_infimum = 1
    if sql_server
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id        )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)order by emails_sum) as t1 order by t1.emails_sum asc"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      infimum.each do |inf|
        infimum.delete(inf) if inf['emails_sum'] == '0' || inf['emails_sum'] == 0.0
      end
      strate_infimum = infimum[0]['emails_sum'] unless infimum.empty?

      # couples query
      sqlstr = "select first_sender, first_receiver, second_sender, second_receiver, inner_ratio, outer_ratio from (select t1.from_employee_id as first_sender, t1.to_employee_id as first_receiver, t2.from_employee_id as second_sender, t2.to_employee_id as second_receiver, t1.emails_sum as inner_ratio,t2.emails_sum as outer_ratio from (select to_employee_id, from_employee_id, cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float) as emails_sum from email_snapshot_data significant_level = 3 and as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where significant_level = 3 and snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id))as t1
      inner join (select from_employee_id, to_employee_id, cast((    #{return_ns})as float)/ cast((       select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id           ) as float) as emails_sum from email_snapshot_data as apsd where significant_level = 3 and snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)) as t2 on t1.to_employee_id=t2.from_employee_id) as t5 where first_sender<>second_receiver"

      # couples query outgrade
      sqlstr = "select from_employee_id, to_employee_id, (case when (cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id           ) as float))<>0 then (cast((#{return_ns})as float)/ cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where significant_level = 3 and snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id           ) as float)) else 0 end) as emails_sum from email_snapshot_data as apsd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      # couples query  ingrade
      sqlstr = "select from_employee_id, to_employee_id, cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      all_couples_in_group = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = find_candidates(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      candidates = create_base_line_for_log(emps, candidates)
    else
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1       )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)order by emails_sum) as t1 order by t1.emails_sum asc"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      infimum.each do |inf|
        infimum.delete(inf) if inf['emails_sum'] == '0'
      end
      strate_infimum = 1
      strate_infimum = infimum[0]['emails_sum'] unless infimum.empty?

      # couples query
      sqlstr = "select first_sender, first_receiver, second_sender, second_receiver, inner_ratio, outer_ratio from (select t1.from_employee_id as first_sender, t1.to_employee_id as first_receiver, t2.from_employee_id as second_sender, t2.to_employee_id as second_receiver, t1.emails_sum as inner_ratio,t2.emails_sum as outer_ratio from (select to_employee_id, from_employee_id, cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id))as t1
      inner join (select from_employee_id, to_employee_id, cast((    #{return_ns})as float)/ cast((       select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1          ) as float) as emails_sum from email_snapshot_data as apsd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)) as t2 on t1.to_employee_id=t2.from_employee_id) as t5 where first_sender<>second_receiver"

      # couples query outgrade
      sqlstr = "select from_employee_id, to_employee_id, (case when (cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1          ) as float))<>0 then (cast((#{return_ns})as float)/ cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1          ) as float)) else 0 end) as emails_sum from email_snapshot_data as apsd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      # couples query  ingrade
      sqlstr = "select from_employee_id, to_employee_id, cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      candidates = {}
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      all_couples_in_group = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = find_candidates(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      candidates = create_base_line_for_log(emps, candidates)
    end
    all_couples_in_group = do_log(emps, candidates, strate_infimum)
    if all_couples_in_group.empty?
      emps.each do |emp|
        result.push(id: emp.to_i, measure: 0)
      end
      return result
    end
    q4 = find_q3_min(json_to_array(all_couples_in_group))
    iqr = q4 - find_q1_max(json_to_array(all_couples_in_group))
    limit = q4 + (iqr * 1.5)
    result = find_bottlenecks(all_couples_in_group, limit)
    id_arr = json_to_id_array(result)
    result_arr = []
    all_couples_in_group.each do |couples|
      result_arr.push(id: couples[:candidate], measure: couples[:email_ratio]) if id_arr.include?(couples[:candidate])
      result_arr.push(id: couples[:candidate], measure: 0) unless id_arr.include?(couples[:candidate])
    end
    return result_arr
  end

  ######################################## Bottlenecks ##############################################

  ##-------------------------------------- Building blocks ------------------------------------------

  ## Handle caching
  def self.calculate_bottlenecks_scores(snapshot_id, pid = NO_PIN, gid = NO_GROUP, emps = [], sql_server = false)
    res = read_or_calculate_and_write("pre_calculate_bottlenecks_scores-#{snapshot_id}-#{pid}-#{gid}") do
      pre_calculate_bottlenecks_scores(snapshot_id, pid, gid, emps, sql_server)
    end
    return res
  end

  ## Performs the actual calculation, without selelcting the flags
  def self.pre_calculate_bottlenecks_scores(snapshot_id, _pid = NO_PIN, _gid = NO_GROUP, emps = [], sql_server = false)
    strate_infimum = 1
    candidates = {}
    outgroupgrades = nil
    ingroupgrades  = nil

    if sql_server
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id        )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)) as t1 order by t1.emails_sum"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      infimum.each do |inf|
        infimum.delete(inf) if inf['emails_sum'] == '0' || inf['emails_sum'] == 0.0
      end
      strate_infimum = infimum[0]['emails_sum'] unless infimum.empty?
      # couples query outgrade
      sqlstr = "select from_employee_id, to_employee_id,(case when cast((      select  top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id           ) as float)<>0 then cast((#{return_ns})as float)/ cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id           ) as float) else 0 end) as emails_sum from email_snapshot_data as apsd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      # couples query  ingrade
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    else
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1       )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)order by emails_sum) as t1"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      infimum.each do |inf|
        infimum.delete(inf) if inf['emails_sum'] == '0'
      end
      strate_infimum = infimum[0]['emails_sum'] unless infimum.empty?

      # couples query outgrade
      sqlstr = "select from_employee_id, to_employee_id,(case when cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1          ) as float)<>0 then cast((#{return_ns})as float)/ cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by from_employee_id limit 1          ) as float) else 0 end) as emails_sum from email_snapshot_data as apsd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      # couples query  ingrade
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      candidates = {}
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    end

    candidates = calculate_inner_ratios_for_bottlenecks(ingroupgrades, outgroupgrades, emps, strate_infimum)
    candidates = create_base_line_for_log(emps, candidates)
    return do_log(emps, candidates, strate_infimum)
  end

  ## Select the flags once the underlying calculation has been done
  def self.select_bottlenecks_flags(all_couples_in_group, emps)
    if all_couples_in_group.empty?
      result = []
      emps.each { |emp| result.push(id: emp.to_i, measure: 0) }
      return result
    end
    q3 = find_q3_min(json_to_array(all_couples_in_group))
    iqr = q3 - find_q1_max(json_to_array(all_couples_in_group))
    limit = q3 + (iqr * 1.5)
    result = find_bottlenecks(all_couples_in_group, limit)
    return result
  end

  ## Only calculate the flag proportion in group, used for the gauge
  def self.calculate_bottlenecks_proportion_in_groups(group_id, resarr, emps)
    return [{ group_id: group_id, measure: resarr.count.to_f / emps.count.to_f }]
  end

  ##-------------------------------------- End Building blocks --------------------------------------

  def self.calculate_bottlenecks_for_flag(sid, pid = NO_PIN, gid = NO_GROUP, sql_server = false)
    cid = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, cid)

    ## Hanlde groups with small numbers
    return emps.map { |emp| { id: emp.to_i, measure: 0 } } if emps.count < 3

    all_couples_in_group = calculate_bottlenecks_scores(sid, pid, gid, emps, sql_server)
    result = select_bottlenecks_flags(all_couples_in_group, emps)

    res = []
    id_arr = json_to_id_array_int(result)
    emps.each do |emp|
      measure = (id_arr.include?(emp.to_i) ? 1 : 0)
      res.push(id: emp.to_i, measure: measure)
    end
    return res
  end

  def self.calculate_bottlenecks(sid, pid = NO_PIN, gid = NO_GROUP, sql_server = false)
    cid = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, cid)
    group_id = (gid == -1 ? pid : gid)

    ## Handle small groups
    return [{ group_id: group_id, measure: 0 }] if emps.count < 3

    all_couples_in_group = calculate_bottlenecks_scores(sid, pid, gid, emps, sql_server)
    return [{ group_id: group_id, measure: 0 }] if all_couples_in_group.empty?
    result = select_bottlenecks_flags(all_couples_in_group, emps)
    res = calculate_bottlenecks_proportion_in_groups(group_id, result, emps)
    return res
  end

  def self.calculate_bottlenecks_explore(sid, pid = NO_PIN, gid = NO_GROUP, sql_server = false)
    return calculate_bottlenecks_for_flag_to_explore(sid, pid, gid, sql_server)
  end

  def self.calculate_bottlenecks_for_flag_to_explore(sid, pid = NO_PIN, gid = NO_GROUP, sql_server = false)
    cid = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, cid)
    all_couples_in_group = calculate_bottlenecks_scores(sid, pid, gid, emps, sql_server)

    res = all_couples_in_group.map do |e|
      { id: e[:candidate], measure: e[:email_ratio] }
    end
    return res
  end
  #################################################### End bottlenecks ############################################

  def self.calculate_representatives_for_flag_to_explore(snapshot_id, pid = NO_PIN, gid = NO_GROUP, sql_server: false)
    results = calculate_representatives_flag(snapshot_id, pid, gid, sql_server: sql_server)
    results.each do |obj|
      obj[:measure] *= 5
    end
    results
  end

  ###########################################################################
  ##
  ## fault lines measure how much people who share a mutual attribute are connected
  ## via a certain network (internal) and how much people that do not share the
  ## attribute are connected (external).
  ##
  ## return the ratio between the internal and external grades relative to the size of the group
  ##
  ###########################################################################

  def self.calculate_internal_faultlines_for_network(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP, rubrica)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid).join(',')
    sqlstr = "select count(*) from network_snapshot_data as internal
             where network_id = #{network_id} and snapshot_id= #{snapshot_id} and (
               (from_employee_id in (select frm.id from employees as frm inner join employees as toes on frm.#{rubrica}=toes.#{rubrica} where frm.id in (#{emps}) and frm.id=from_employee_id and toes.id=to_employee_id)
               and to_employee_id in (select toes.id from employees as frm inner join employees as toes on frm.#{rubrica}=toes.#{rubrica} where frm.id in (#{emps}) and frm.id=from_employee_id and toes.id=to_employee_id)))
                and from_employee_id in (#{emps}) and to_employee_id in (#{emps}) and value = 1"
    internal = ActiveRecord::Base.connection.select_all(sqlstr)[0].to_hash

    count_hash = is_sql_server_connection? ? '' : 'count'

    internal = internal[count_hash].to_f
    sqlstr = "select count(*) from network_snapshot_data as internal
             where network_id = #{network_id} and snapshot_id= #{snapshot_id} and (
               (from_employee_id in (select frm.id from employees as frm inner join employees as toes on frm.#{rubrica}<>toes.#{rubrica} where frm.id in (#{emps}) and frm.id=from_employee_id and toes.id=to_employee_id) and to_employee_id in
                                     (select toes.id from employees as frm inner join employees as toes on frm.#{rubrica}<>toes.#{rubrica} where frm.id in (#{emps}) and frm.id=from_employee_id and toes.id=to_employee_id)))
                and from_employee_id in (#{emps}) and to_employee_id in (#{emps}) and value = 1"
    external = ActiveRecord::Base.connection.select_all(sqlstr)[0].to_hash
    external = external[count_hash].to_f
    return 0 if (external + internal) == 0
    at = (external - internal) / (external + internal)
    return at
  end

  def self.calculate_external_faultlines_for_network(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid).join(',')
    sqlstr = "select count(*) from network_snapshot_data as internal
             where network_id = #{network_id} and snapshot_id= #{snapshot_id}
             and from_employee_id in (#{emps}) and to_employee_id in (#{emps}) and value = 1"
    internal = ActiveRecord::Base.connection.select_all(sqlstr)[0].to_hash

    count_hash = is_sql_server_connection? ? '' : 'count'

    internal = internal[count_hash].to_f
    sqlstr = "select count(*) from network_snapshot_data as internal
             where network_id = #{network_id} and snapshot_id= #{snapshot_id} and (from_employee_id not in (#{emps}) or to_employee_id not in (#{emps})) and value = 1"
    external = ActiveRecord::Base.connection.select_all(sqlstr)[0].to_hash
    external = external[count_hash].to_f
    return 0 if (external + internal) == 0
    at = (external - internal) / (external + internal)
    return at
  end

  def self.calculate_internal_faultlines_for_emails(snapshot_id, pid = NO_PIN, gid = NO_GROUP, rubrica)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid).join(',')
    network = NetworkSnapshotData.emails(cid)
    sqlstr = "SELECT COUNT(id)            AS emails_sum
              FROM network_snapshot_data  AS int
              WHERE snapshot_id= #{snapshot_id}
              AND network_id        = #{network}
              AND (from_employee_id IN (
                SELECT frm.id
                FROM employees            AS frm
                INNER JOIN employees      AS toes ON frm.#{rubrica}=toes.#{rubrica}
                WHERE frm.id        IN (#{emps})
                AND frm.id=from_employee_id
                AND toes.id=to_employee_id
                )
              AND to_employee_id    IN (
                SELECT toes.id
                FROM employees            AS frm
                INNER JOIN employees      AS toes ON frm.#{rubrica}=toes.#{rubrica}
                WHERE frm.id        IN (#{emps})
                AND frm.id=from_employee_id
                AND toes.id=to_employee_id
                )
              )
              AND from_employee_id  IN (#{emps})
              AND to_employee_id    IN (#{emps})"
    internal = ActiveRecord::Base.connection.select_all(sqlstr)[0].to_hash

    internal = internal['emails_sum'].to_f
    sqlstr = "SELECT COUNT(id)            AS emails_sum
              FROM network_snapshot_data  AS ext
              WHERE snapshot_id= #{snapshot_id}
              AND network_id        = #{network}
              AND (from_employee_id IN (
                SELECT frm.id 
                FROM employees            AS frm
                INNER JOIN employees      AS toes ON frm.#{rubrica}<>toes.#{rubrica}
                WHERE frm.id        IN (#{emps})
                AND frm.id=from_employee_id
                AND toes.id=to_employee_id
                )
              AND to_employee_id   IN (
                 SELECT toes.id
                 FROM employees           AS frm
                 INNER JOIN employees     AS toes ON frm.#{rubrica}<>toes.#{rubrica}
                 WHERE frm.id       IN (#{emps})
                 AND frm.id=from_employee_id
                 AND toes.id=to_employee_id
                 )
              )
              AND from_employee_id  IN (#{emps})
              AND to_employee_id    IN (#{emps})"
    external = ActiveRecord::Base.connection.select_all(sqlstr)[0].to_hash
    external = external['emails_sum'].to_f
    return 0 if (external + internal) == 0
    at = (external - internal) / (external + internal)
    return at
  end

  def self.calculate_external_faultlines_for_emails(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid).join(',')
    network = NetworkSnapshotData.emails(cid)
    sqlstr = "SELECT COUNT(id)            AS emails_sum
              FROM network_snapshot_data  AS int
              WHERE snapshot_id= #{snapshot_id}
              AND network_id        = #{network}
              AND from_employee_id  IN (#{emps})
              AND to_employee_id    IN (#{emps})"

    internal = ActiveRecord::Base.connection.select_all(sqlstr)[0].to_hash
    internal = internal['emails_sum'].to_f
    sqlstr = "SELECT COUNT(id)            AS emails_sum
              FROM network_snapshot_data  AS ext
              WHERE snapshot_id= #{snapshot_id}
              AND network_id          = #{network}
              AND (from_employee_id   NOT IN (#{emps})
                OR to_employee_id     NOT IN (#{emps}))"
    external = ActiveRecord::Base.connection.select_all(sqlstr)[0].to_hash
    external = external['emails_sum'].to_f
    return 0 if (external + internal) == 0
    at = (external - internal) / (external + internal)
    return at
  end

  def self.get_company_id(snapshot_id)
    company_id = Snapshot.where('id = ?', snapshot_id).first.company_id unless Snapshot.where('id = ?', snapshot_id).empty?
    return company_id
  end

  def self.sum_the_emails_by_ids(multiplicity, from_type, to_type, emps, snapshot_id, company_id)
    network = NetworkSnapshotData.emails(company_id)
    sqlstr = "SELECT COUNT(id)            AS emails_sum
              FROM network_snapshot_data  AS internal
              WHERE snapshot_id=    #{snapshot_id}
              AND network_id=       #{network}
              AND multiplicity=     #{multiplicity}
              AND from_type=        #{from_type}
              AND to_type=          #{to_type}
              AND from_employee_id  IN (#{emps})
              AND to_employee_id    IN (#{emps})"
    nonesum = ActiveRecord::Base.connection.select_all(sqlstr)[0].to_hash
    return nonesum['emails_sum'].to_f
  end

  ###########################################################################
  ## measures how many emails have been inititiated exclusively with relation to mailing lists
  ###########################################################################

  def self.proportion_of_emails(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid).join(',')
    nonesum = sum_the_emails_by_ids(1, 1, 1, emps, snapshot_id, cid)
    ntensum = sum_the_emails_by_ids(2, 1, 1, emps, snapshot_id, cid)
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: 0 }] if (nonesum.to_f + ntensum.to_f) == 0
    at = nonesum.to_f / (nonesum + ntensum).to_f
    return [{ group_id: group_id, measure: at }]
  end

  def self.list_to_hash(list)
    hash = {}
    list.each do |emp|
      hash[emp['from_employee_id'].to_i] = emp['emails_sum'].to_i
    end
    hash
  end

  def self.json_to_array(json_obj)
    res = []
    json_obj.each do |obj|
      res.push(obj[:email_ratio].to_f)
    end
    return res
  end

  def self.find_bottlenecks(arr, limit)
    res = []
    arr.each do |obj|
      res.push(obj) if obj[:email_ratio].to_f > limit
    end
    return res
  end

  def self.find_bottlenecks_for_flags(arr, limit)
    res = []
    arr.each do |obj|
      res.push(obj) if obj[:email_ratio].to_f > limit
    end
    return res
  end

  def self.json_to_id_array(json_obj)
    res = []
    json_obj.each do |obj|
      res.push(obj[:id])
    end
    return res
  end

  def self.json_to_id_array_int(json_obj)
    res = []
    json_obj.each do |obj|
      res.push(obj[:candidate].to_i)
    end
    return res
  end

  def self.is_there_zero(emps, hashtable)
    emps.each do |li|
      return true if hashtable[li.to_s].to_f == 0 && !hashtable[li.to_s].nil?
    end
    return false
  end

  def self.calculate_ratios(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
    candidates = {}
    ingroupgrades = json_to_hash_table(ingroupgrades)
    outgroupgrades = json_to_hash_table(outgroupgrades)
    str_emps = emps_without_managers(emps)
    str_out_emps = emps_without_managers(out_emps)
    str_emps.each do |candidate|
      str_emps.each do |from|
        str_out_emps.each do |to|
          next if from == to || candidate == from || candidate == to
          candidates[candidate] = 0.to_f if candidates[candidate].nil?
          candidates[candidate] += ingroupgrades[from + '_' + candidate] * outgroupgrades[candidate + '_' + to] / outgroupgrades[from + '_' + to] if outgroupgrades[from + '_' + to] != 0
          candidates[candidate] += ingroupgrades[from + '_' + candidate] * outgroupgrades[candidate + '_' + to] / strate_infimum.to_f if outgroupgrades[from + '_' + to] == 0
        end
      end
    end
    candidates
  end

  def self.calculate_representatives(snapshot_id, pid = NO_PIN, gid = NO_GROUP, sql_server: false)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid)
    out_emps = get_members_not_in_group(emps, cid)
    group_id = (gid == -1 ? pid : gid)
    strate_infimum = 1
    candidates = {}
    return [{ group_id: group_id, measure: 0 }] if emps.count < 3 || out_emps.count < 2
    if sql_server
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id        )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)) as t1 order by t1.emails_sum"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      strate_infimum = find_infimum(infimum)
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id           ) as float)<>0 then cast((#{return_ns})as float)/ cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id           ) as float) else 0 end) as emails_sum from email_snapshot_data as apsd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = calculate_ratios(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      if is_there_zero(emps, candidates)
        emps.each do |candidate|
          candidates[candidate.to_s] += 1
        end
      end
    else
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id limit 1       )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)order by emails_sum) as t1"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      strate_infimum = find_infimum(infimum)
      # sqlstr = "select distinct t1.emails_sum from (select cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by to_employee_id limit 1       )as float) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)order by emails_sum) as t1"
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id limit 1          ) as float)<>0 then cast((#{return_ns})as float)/ cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id limit 1          ) as float) else 0 end) as emails_sum from email_snapshot_data as apsd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = calculate_ratios(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      if is_there_zero(emps, candidates)
        emps.each do |candidate|
          candidates[candidate.to_s] += 1
        end
      end
    end
    all_couples_in_group = do_log(emps, candidates, strate_infimum)
    return [{ group_id: group_id, measure: 0 }] if all_couples_in_group.empty?
    q4 = find_q3_min(json_to_array(all_couples_in_group))
    iqr = q4 - find_q1_max(json_to_array(all_couples_in_group))
    limit = q4 + (iqr * 1.5)
    result = find_bottlenecks(all_couples_in_group, limit)
    return [{ group_id: group_id, measure: result.count.to_f / emps.count.to_f }]
  end

  def self.calculate_representatives_to_explore(snapshot_id, pid = NO_PIN, gid = NO_GROUP, sql_server: false)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid)
    out_emps = get_members_not_in_group(emps, cid)
    result = []
    if emps.count < 3 || out_emps.empty?
      emps.each do |emp|
        result.push(id: emp.to_i, measure: 0)
      end
      return result
    end
    strate_infimum = 1
    candidates = {}
    if sql_server
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id        )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)) as t1 order by t1.emails_sum"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      strate_infimum = find_infimum(infimum)
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id           ) as float)<>0 then cast((#{return_ns})as float)/ cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id           ) as float) else 0 end) as emails_sum from email_snapshot_data as apsd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = calculate_ratios(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      if is_there_zero(emps, candidates)
        emps.each do |candidate|
          candidates[candidate.to_s] += 1
        end
      end
    else
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id limit 1       )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)order by emails_sum) as t1"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      strate_infimum = find_infimum(infimum)
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id limit 1          ) as float)<>0 then cast((#{return_ns})as float)/ cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id limit 1          ) as float) else 0 end) as emails_sum from email_snapshot_data as apsd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = calculate_ratios(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      if is_there_zero(emps, candidates)
        emps.each do |candidate|
          candidates[candidate.to_s] += 1
        end
      end
    end
    all_couples_in_group = do_log(emps, candidates, strate_infimum)
    if all_couples_in_group.empty?
      emps.each do |emp|
        result.push(id: emp.to_i, measure: 0)
      end
      return result
    end
    q4 = find_q3_min(json_to_array(all_couples_in_group))
    iqr = q4 - find_q1_max(json_to_array(all_couples_in_group))
    limit = q4 + (iqr * 1.5)
    result = find_bottlenecks(all_couples_in_group, limit)
    id_arr = json_to_id_array(result)
    result_arr = []
    all_couples_in_group.each do |couples|
      result_arr.push(id: couples[:candidate], measure: couples[:email_ratio]) if id_arr.include?(couples[:candidate])
      result_arr.push(id: couples[:candidate], measure: 0) unless id_arr.include?(couples[:candidate])
    end
    return result_arr
  end

  def self.find_infimum(infimum)
    infimum.each do |inf|
      infimum.delete(inf) if inf['emails_sum'] == '0' || inf['emails_sum'] == 0.0
    end
    strate_infimum = 1
    strate_infimum = infimum[0]['emails_sum'] unless infimum.empty?
    return strate_infimum
  end

  def self.grade_employees(emps, id_arr)
    res = []
    emps.each do |emp|
      if id_arr.include?(emp.to_i)
        res.push(id: emp.to_i, measure: 1)
      else
        res.push(id: emp.to_i, measure: 0)
      end
    end
    return res
  end

  def self.push_empties(emps)
    result = []
    emps.each do |emp|
      result.push(id: emp.to_i, measure: 0)
    end
    return result
  end

  def self.calculate_representatives_flag(snapshot_id, pid = NO_PIN, gid = NO_GROUP, sql_server: false)
    cid = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, cid)
    out_emps = get_members_not_in_group(emps, cid)
    result = []
    if emps.count < 3 || out_emps.count < 2
      result = push_empties(emps)
      return result
    end
    strate_infimum = 1
    candidates = {}
    if sql_server
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select top 1  sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id        )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)) as t1 order by t1.emails_sum"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      strate_infimum = find_infimum(infimum)
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float)<>0 then cast((#{return_ns}) as float)/cast((      select top 1 sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id        )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id           ) as float)<>0 then cast((#{return_ns})as float)/ cast((      select top 1 cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id           ) as float) else 0 end) as emails_sum from email_snapshot_data as apsd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = calculate_ratios(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      if is_there_zero(emps, candidates)
        emps.each do |candidate|
          candidates[candidate.to_s] += 1
        end
      end
    else
      sqlstr = "select distinct t1.emails_sum from (select from_employee_id, to_employee_id,(case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = aesd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id limit 1       )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id, toes.id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=#{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)order by emails_sum) as t1"
      infimum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      strate_infimum = find_infimum(infimum)
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float)<>0 then cast((#{return_ns}) as float)/cast((      select sum(#{return_ns}) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.to_employee_id = aesd.to_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{emps.join(',')}) group by to_employee_id limit 1       )as float) else 0 end) as emails_sum from email_snapshot_data as aesd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (#{emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{emps.join(',')}) and not exists (select 1 from email_snapshot_data as esd where snapshot_id=#{snapshot_id} and esd.to_employee_id=toes.id and esd.from_employee_id=frm.id)"
      ingroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      sqlstr = "select from_employee_id, to_employee_id, (case when cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id limit 1          ) as float)<>0 then cast((#{return_ns})as float)/ cast((      select  cast((sum(#{return_ns})) as float) from email_snapshot_data as denom where snapshot_id=#{snapshot_id} and denom.from_employee_id = apsd.from_employee_id and denom.from_employee_id in (#{emps.join(',')}) and denom.to_employee_id in (#{out_emps.join(',')}) group by from_employee_id limit 1          ) as float) else 0 end) as emails_sum from email_snapshot_data as apsd where snapshot_id=#{snapshot_id} and from_employee_id in (#{emps.join(',')}) and to_employee_id in (    #{out_emps.join(',')}) and to_employee_id<>from_employee_id union all select frm.id as sender, toes.id as to_employee_id, 0 as emails_sum from employees as frm inner join employees as toes on frm.id<>toes.id where frm.id in (#{emps.join(',')}) and toes.id in (#{out_emps.join(',')}) and not exists (select 1 from email_snapshot_data where snapshot_id=  #{snapshot_id} and to_employee_id=toes.id and from_employee_id=frm.id)"
      outgroupgrades = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      candidates = calculate_ratios(ingroupgrades, outgroupgrades, emps, out_emps, strate_infimum)
      if is_there_zero(emps, candidates)
        emps.each do |candidate|
          candidates[candidate.to_s] += 1
        end
      end
    end
    all_couples_in_group = do_log(emps, candidates, strate_infimum)
    if all_couples_in_group.empty?
      result = push_empties(emps)
      return result
    end
    q4 = find_q3_min(json_to_array(all_couples_in_group))
    iqr = q4 - find_q1_max(json_to_array(all_couples_in_group))
    limit = q4 + (iqr * 1.5)
    result = find_bottlenecks(all_couples_in_group, limit)
    id_arr = json_to_id_array_int(result)
    res = grade_employees(emps, id_arr)
    return res
  end

  def calc_average_internal(grade_for_network)
    grade = 0
    grade_for_network.each do |grd|
      grade += grd
    end
    grade /= 4
    return grade
  end

  ################################## FRIENDSHIPS ##################################

  ###########################################################################
  ##
  ## Non-reciprocity is high for employees who tend to say be connected to
  ## employees who do not reciprocate the connection.
  ##
  ## 1 - For everyemployee get his outdegree and the number of his out going
  ##     connections which reciprocate.
  ## 2 - get the difference and then the ratio.
  ## 3 - return the reult vector
  ##
  ###########################################################################
  def self.employees_network_non_reciprocity_scores(sid, nid, pid, gid)
    cid = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, cid).sort
    return [] if emps.count == 0
    empsstr = emps.join(',')

    sqlstr =
      "select from_employee_id, count(*) from network_snapshot_data as out
      where snapshot_id = #{sid} and company_id = #{cid} and network_id = #{nid} and
        to_employee_id in (#{empsstr}) and from_employee_id in (#{empsstr}) and
        value = 1 and
        to_employee_id in
          (select from_employee_id from network_snapshot_data as innr
           where snapshot_id = #{sid} and company_id = #{cid} and network_id = #{nid} and
             to_employee_id in (#{empsstr}) and from_employee_id in (#{empsstr}) and
             innr.to_employee_id = out.from_employee_id and value = 1)
           group by from_employee_id order by from_employee_id"
    symetric_count = ActiveRecord::Base.connection.select_all(sqlstr)

    sqlstr =
      "select from_employee_id, count(*) from network_snapshot_data as out
      where snapshot_id = #{sid} and company_id = #{cid} and network_id = #{nid} and
        value = 1 and
        to_employee_id in (#{empsstr}) and from_employee_id in (#{empsstr}) and value = 1
        group by from_employee_id order by from_employee_id"
    all_count = ActiveRecord::Base.connection.select_all(sqlstr)

    count_hash = is_sql_server_connection? ? '' : 'count'

    symetric_count_hash = {}
    symetric_count.each { |sc| symetric_count_hash[sc['from_employee_id'].to_s] = sc[count_hash].to_i }
    all_count_hash = {}
    all_count.each { |ac| all_count_hash[ac['from_employee_id'].to_s] = ac[count_hash].to_i }

    scores = {}
    emps.each do |eid|
      sch = symetric_count_hash[eid.to_s].nil? ? 0 : symetric_count_hash[eid.to_s]
      ach = (all_count_hash[eid.to_s].nil? || all_count_hash[eid.to_s] == 0 ? 0 : all_count_hash[eid.to_s])
      if ach == 0
        scores[eid.to_s] = 0.0
        next
      end
      scores[eid.to_s] = (1 - (sch.to_f / ach.to_f)).round(2)
    end

    return scores
  end

  ###########################################################################
  ##
  ## Non-reciprocity here means the difference between sending emails and
  ## reciving emails from same employees.
  ##
  ## 1 - select rows like:
  ##   {"from_employee_id"=>"1", "to_employee_id"=>"2", "outsum"=>"2", "diff"=>"0"}
  ##   where outsum are emp 1 outdegrees and diff is the difference between his
  ##   outdgree to emp 2 and the indgree from emp2
  ## 2 - for each entry calculate the ratio between indegree and outdgree
  ## 3 - Sum for every employee, and return the result
  ############################################################################
  def self.employees_email_non_reciprocity_scores(sid, pid, gid)
    cid = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, cid).sort
    return [] if emps.count == 0
    empsstr = emps.join(',')
    network = NetworkSnapshotData.emails(cid)
    sqlstr ="SELECT out.from_employee_id, out.to_employee_id,
            COUNT(id)                     AS outsum,
            COUNT(id) - sss.insum         AS diff
            FROM network_snapshot_data    AS out
            LEFT JOIN (
              SELECT inn.from_employee_id, inn.to_employee_id,
              COUNT(id)                   AS insum
              FROM network_snapshot_data  AS inn
              WHERE snapshot_id         = #{sid}
              AND inn.to_employee_id    IN (#{empsstr})
              AND inn.from_employee_id  IN (#{empsstr})
              GROUP BY inn.from_employee_id, inn.to_employee_id
              )                           AS sss
            ON sss.from_employee_id = out.to_employee_id
            AND sss.to_employee_id  = out.from_employee_id
            WHERE snapshot_id           =  #{sid}
            AND network_id              =  #{network}
            AND out.to_employee_id      IN (#{empsstr})
            AND out.from_employee_id    IN (#{empsstr})
            GROUP BY out.from_employee_id, out.to_employee_id, sss.insum
            ORDER BY out.from_employee_id"
    outdegrees = ActiveRecord::Base.connection.select_all(sqlstr)
    outdegrees_hash = {}
    outdegrees.each do |indeg|
      ratio = -1

      ## The join from above return a nil in diff value if to_emp did not return email traffic to from_emp
      ## It will return a negative number if the email traffix was less
      ## and positive diff otherwise.
      ratio = if indeg['diff'].nil?
                1
              elsif indeg['diff'].to_i <= 0
                0
              else
                (indeg['diff'].to_f / indeg['outsum'].to_f).round(2)
              end

      if outdegrees_hash[indeg['from_employee_id']].nil?
        outdegrees_hash[indeg['from_employee_id']] = ratio
      else
        outdegrees_hash[indeg['from_employee_id']] += ratio
      end
    end

    outdegrees_unique_hash = {}
    outdegrees_hash.each do |e|
      outdegrees_unique_hash[e[0].to_s] = e[1]
    end

    return outdegrees_unique_hash
  end

  ###################################################################
  ##
  ## Get non reciprocity vectors from all three networks (typicallY:
  ##  Trust, Friendship and emails). For each network extract high
  ##  quartile, and return only employees who appear in all three.
  ##
  ###################################################################
  def pre_calculate_non_reciprocity_between_employees(sid, nid_1, nid_2, pid = NO_PIN, gid = NO_GROUP)
    net1_scores  = employees_network_non_reciprocity_scores(sid, nid_1, pid, gid)
    net2_scores  = employees_network_non_reciprocity_scores(sid, nid_2, pid, gid)
    email_scores = employees_email_non_reciprocity_scores(sid, pid, gid)

    cid = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, cid)

    net1_scores_q4  = to_ids_array(slice_percentile_from_hash_array(net1_scores,  Q3, emps))
    net2_scores_q4  = to_ids_array(slice_percentile_from_hash_array(net2_scores,  Q3, emps))
    email_scores_q4 = to_ids_array(slice_percentile_from_hash_array(email_scores, Q3, emps))

    email_scores_q4 = harsh_idscore_to_upperlower_quartile_emp_ids(email_scores, emps) if find_empty_networks(sid, nid_1, nid_2, emps)
    net2_scores_q4 = harsh_idscore_to_upperlower_quartile_emp_ids(net2_scores, emps) if find_empty_network_and_email(sid, nid_1, emps)
    net1_scores_q4 = harsh_idscore_to_upperlower_quartile_emp_ids(net1_scores, emps) if find_empty_network_and_email(sid, nid_2, emps)
    # there are four different possibilities that we check in this lambda function:
    #  1. there are emails and at least one network.
    #  2. there are only emails.
    #  3. there is only one network x.
    #  4. there is only one network y.
    high_in_all_networks = lambda do |emp|
      emp_s = emp.to_s
      (!find_empty_networks(sid, nid_1, nid_2, emps) && !find_empty_network_and_email(sid, nid_1, emps) && !find_empty_network_and_email(sid, nid_2, emps) && net1_scores_q4.include?(emp) &&
        (!net1_scores[emp_s].nil? && net1_scores[emp_s] >= 0) &&
        net2_scores_q4.include?(emp) &&
        (!net2_scores[emp_s].nil? && net2_scores[emp_s] >= 0) &&
        email_scores_q4.include?(emp) &&
        (!email_scores[emp_s].nil? && email_scores[emp_s] >= 0)) ||

        (find_empty_networks(sid, nid_1, nid_2, emps) && !find_empty_network_and_email(sid, nid_1, emps) && !find_empty_network_and_email(sid, nid_2, emps) && email_scores_q4.include?(emp) &&
          (!email_scores[emp_s].nil? && email_scores[emp_s] >= 0)) ||

        (!find_empty_networks(sid, nid_1, nid_2, emps) && !find_empty_network_and_email(sid, nid_1, emps) && find_empty_network_and_email(sid, nid_2, emps) && net1_scores_q4.include?(emp) &&
          (!net1_scores[emp_s].nil? && net1_scores[emp_s] >= 0)) ||
        (!find_empty_networks(sid, nid_1, nid_2, emps) && find_empty_network_and_email(sid, nid_1, emps) && !find_empty_network_and_email(sid, nid_2, emps) && net2_scores_q4.include?(emp) &&
          (!net2_scores[emp_s].nil? && net2_scores[emp_s] >= 0))
    end

    return [emps, high_in_all_networks]
  end

  def self.find_empty_networks(sid, nid_1, nid_2, emps)
    NetworkSnapshotData.where(snapshot_id: sid, network_id: nid_1, to_employee_id: emps, from_employee_id: emps).empty? && NetworkSnapshotData.where(snapshot_id: sid, network_id: nid_2, to_employee_id: emps, from_employee_id: emps).empty?
  end

  def self.find_empty_network_and_email(sid, nid_1, emps)
    NetworkSnapshotData.where(snapshot_id: sid, network_id: nid_1, to_employee_id: emps, from_employee_id: emps).empty?
  end

  def self.calculate_non_reciprocity_between_employees_hidden_gauge(sid, nid_1, nid_2, pid = NO_PIN, gid = NO_GROUP)
    employees_with_high_non_reciprocity = calculate_non_reciprocity_between_employees(sid, nid_1, nid_2, pid, gid)
    counter = 0
    employees_with_high_non_reciprocity.each do |grade|
      counter += 1 if grade[:measure] == 1
    end
    group_id = (gid == -1 ? pid : gid)
    company = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, company)
    return [{ group_id: group_id, measure: 0 }] if emps.count == 0
    return [{ group_id: group_id, measure: counter.to_f / emps.count.to_f }]
  end

  def self.calculate_non_reciprocity_between_employees(sid, nid_1, nid_2, pid = NO_PIN, gid = NO_GROUP)
    emps, high_in_all_networks = pre_calculate_non_reciprocity_between_employees(sid, nid_1, nid_2, pid, gid)
    flagged_emps = []
    emps.each do |emp|
      flagged_emps << { id: emp, measure: 1 } if high_in_all_networks.call(emp)
    end
    return flagged_emps
  end

  def self.calculate_non_reciprocity_between_employees_explore(sid, nid_1, nid_2, pid = NO_PIN, gid = NO_GROUP)
    emps, high_in_all_networks = pre_calculate_non_reciprocity_between_employees(sid, nid_1, nid_2, pid, gid)
    v_res = []
    emps.each do |emp|
      s_measure = high_in_all_networks.call(emp) ? 1 : 0
      v_res << { id: emp, measure: s_measure }
    end
    return v_res
  end

  def self.volume_json_to_array(v_email_degs)
    arra = []
    v_email_degs.each do |email_deg|
      arra.push(email_deg[:measure])
    end
    return arra
  end

  def self.volume_for_group(snapshot_id, company, pid, gid)
    all_metrix_and_employees_in_group = calculate_inn_degree_email(snapshot_id, nil, company, pid, gid)
    all_metrix = all_metrix_and_employees_in_group[0]
    emp_arr = all_metrix_and_employees_in_group[1]
    all_metrix_and_employees_off_group = calculate_outn_degree_email(snapshot_id, nil, company, pid, gid)
    v_email_degs = sum_up_in_and_out_emails_for_company(all_metrix_and_employees_off_group, all_metrix, emp_arr)
    return v_email_degs
  end

  def self.volume_of_emails(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    company = Snapshot.find(snapshot_id).company_id
    v_email_degs = volume_for_group(snapshot_id, company, pid, gid)
    v_email_degs = grade_all_groups(company, v_email_degs)
    v_email_degs = sort_results(v_email_degs)
    return v_email_degs
  end

  def self.volume_of_emails_for_explore(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    company = Snapshot.find(snapshot_id).company_id
    emp_arr = get_members_in_group(pid, gid, company)
    arr = []
    emp_arr.each do |emp_one|
      arr.push(id: emp_one, measure: 0)
    end
    return arr
  end

  def self.find_sinks(array, limit)
    result = []
    array.each do |possible_sink|
      result.push(id: possible_sink['empid'].to_i, measure: 1) if possible_sink['emails_sum'].to_f > limit.to_f
      result.push(id: possible_sink['empid'].to_i, measure: 0) if possible_sink['emails_sum'].to_f <= limit.to_f
    end
    result
  end

  def self.find_sinks_to_explore(array, limit)
    result = []
    array.each do |possible_sink|
      result.push(id: possible_sink['to_employee_id'].to_i, measure: possible_sink['emails_sum'].to_f) if possible_sink['emails_sum'].to_f > limit.to_f
      result.push(id: possible_sink['to_employee_id'].to_i, measure: 0) if possible_sink['emails_sum'].to_f <= limit.to_f
    end
    result
  end

  def self.sinks(sid, pid = NO_PIN, gid = NO_GROUP, cid, emps)
    emps = get_members_in_group(pid, gid, cid)
    nid  = NetworkSnapshotData.emails(cid)

    sqlstr =
      "SELECT emps.id AS empid, fromemps.fromempcount, toemps.toempcount
      FROM employees AS emps
      LEFT JOIN (SELECT tonsd.to_employee_id AS toempid, count(*) AS toempcount
            FROM network_snapshot_data AS tonsd
            WHERE
            network_id = #{nid} AND
            snapshot_id = #{sid}
            GROUP BY tonsd.to_employee_id) AS toemps ON toemps.toempid = emps.id
      LEFT JOIN (SELECT fromnsd.from_employee_id AS fromempid, count(*) AS fromempcount
            FROM network_snapshot_data AS fromnsd
            WHERE
            network_id = #{nid} AND
            snapshot_id = #{sid}
            GROUP BY fromnsd.from_employee_id) AS fromemps ON fromemps.fromempid = emps.id
      WHERE emps.id in (#{emps.join(',')})
      ORDER BY emps.id"
    sqlres = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

    ratios = []
    sqlres.each do |e|
      toempcount   = e['toempcount']
      fromempcount = e['fromempcount']
      next if toempcount.nil?

      elm = {}
      elm['empid'] = e['empid']
      elm['emails_sum'] = 100 if (!toempcount.nil? && fromempcount.nil?)
      elm['emails_sum'] = toempcount.to_f / fromempcount.to_f if (!toempcount.nil? && !fromempcount.nil?)

      ratios << elm
    end
    ratios = ratios.sort { |a,b| a['emails_sum'] <=> b['emails_sum'] }
    return ratios
  end

  def self.sinks_gauge(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    sinks_and_not_sinks = flag_sinks(snapshot_id, pid, gid)
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: count_sinks(sinks_and_not_sinks) }]
  end

  def self.sinks_gauge_explore(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    company = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, company)
    result = []
    emps.each do |emp|
      result.push(id: emp, measure: 1)
    end
    return result
  end

  def self.count_sinks(sinks_and_not_sinks)
    count = 0
    sinks_and_not_sinks.each do |possible|
      count += 1 if possible[:measure] == 1
    end
    count
  end

  def self.flag_sinks(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.find(snapshot_id).company.id
    emps = get_members_in_group(pid, gid, cid)
    if NetworkSnapshotData.where(snapshot_id: snapshot_id, network_id: NetworkSnapshotData.emails(cid)).empty?
      ratios = []
      emps.each do |ratio|
        ratios.push(id: ratio.to_i, measure: 0)
      end
      return ratios
    end
    ratios = sinks(snapshot_id, pid, gid, cid, emps)
    q_one = find_q1_max(json_to_array_sinks(ratios))
    q_three = find_q3_min(json_to_array_sinks(ratios))
    iqr = q_three - q_one
    sinks = find_sinks(ratios, q_three + 1.5 * iqr)
    return sinks
  end

  def self.flag_sinks_explore(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    company = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, company)
    if NetworkSnapshotData.emails(cid).where(snapshot_id: snapshot_id).empty?
      ratios = []
      emps.each do |ratio|
        ratios.push(id: ratio.to_i, measure: 0)
      end
      return ratios
    end
    ratios = sinks(snapshot_id, pid, gid, company, emps)
    q_one = find_q1_max(json_to_array_sinks(ratios))
    q_three = find_q3_min(json_to_array_sinks(ratios))
    iqr = q_three - q_one
    return find_sinks_to_explore(ratios, q_three + 1.5 * iqr)
  end

  def self.no_of_isolates(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    company = Snapshot.find(snapshot_id).company_id
    emps = get_members_in_group(pid, gid, company)
    network = NetworkSnapshotData.emails(company)
    sqlstr = "SELECT COUNT(id) AS emails_sum 
              FROM network_snapshot_data
              WHERE network_id      = #{network} 
              AND snapshot_id       = #{snapshot_id} 
              AND to_employee_id  IN (#{emps.join(',')})"
    sum = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    avg_emails = sum[0]['emails_sum'].to_f / emps.count.to_f if emps.count.to_f > 0
    avg_emails = 0 if emps.count.to_f == 0
    sqlstr = "SELECT to_employee_id, 
              (CASE 
                WHEN #{avg_emails}<>0 
                  THEN COUNT(id)/#{avg_emails} 
                ELSE 0
              END)
              AS emails_sum
              FROM network_snapshot_data
              WHERE network_id      = #{network} 
              AND snapshot_id       = #{snapshot_id} 
              AND to_employee_id  IN (#{emps.join(',')}) 
              AND to_employee_id<>from_employee_id 
              GROUP BY to_employee_id"
    indegrees = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    count_degs = 0
    indegrees.each do |deg|
      count_degs += 1 if deg['emails_sum'].to_f <= (1.to_f / 3.to_f).to_f
    end
    count_degs += (emps.count - indegrees.count)
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: count_degs.to_f / emps.count.to_f }] if emps.count != 0
    return [{ group_id: group_id, measure: 0 }] if emps.count == 0
  end

  def self.no_of_isolates_for_explore(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    company = Snapshot.find(snapshot_id).company_id
    emp_arr = get_members_in_group(pid, gid, company)
    arr = []
    emp_arr.each do |emp_one|
      arr.push(id: emp_one, measure: 0)
    end
    return arr
  end

  def self.grade_all_groups(company, v_email_degs)
    group_degrees = []
    Group.where(company_id: company).each do |grp|
      emp_arr = get_members_in_group(NO_PIN, grp.id, company)
      grades_for_employee = 0
      emp_arr.each do |employee|
        grades_for_employee += get_measure_for_employee(v_email_degs, employee)
      end
      group_degrees.push(group_id: grp.id, measure: grades_for_employee.to_f / emp_arr.count.to_f, pin_group: false) if emp_arr.count.to_f != 0
      group_degrees.push(group_id: grp.id, measure: 0, pin_group: false) if emp_arr.count.to_f == 0
    end
    group_degrees
  end

  def self.get_group_and_all_its_descendants(group_id)
    ids_of_groups = get_descendant_groups(group_id, [])
    ids_of_groups.push(group_id) unless Group.find_by_id(group_id).nil?
    ids_of_groups
  end

  def self.get_descendant_groups(group_id, array)
    Group.where(parent_group_id: group_id).each do |grp|
      array.push(grp.id)
      get_descendant_groups(grp.id, array)
    end
    return array.uniq
  end

  def self.grade_group(group_id, v_email_degs)
    sum_for_group = 0
    mems = get_members_in_group(NO_PIN, grp.id, company)
    mems.each do |id|
      sum_for_group += get_measure_for_employee(v_email_degs, id)
    end
    return { id: group_id, measure: sum_for_group, number_of_employees: mems.count }
  end

  def self.grade_pin_groups(company, v_email_degs)
    email_volume_group = []
    # total_number_of_employees = 0
    Pin.where(company_id: company).each do |pin_group|
      sum_for_group = 0
      mems = get_members_in_group(pin_group.id, NO_GROUP, company)
      mems.each do |id|
        sum_for_group += get_measure_for_employee(v_email_degs, id)
      end
      email_volume_group.push(measure: sum_for_group.to_f / mems.count.to_f, group_id: pin_group.id)
      # total_number_of_employees += mems.count
    end
    return email_volume_group
  end

  def self.get_measure_for_employee(v_email_degs, id)
    result = 0
    v_email_degs.each do |deg|
      result = deg[:measure] if deg[:id] == id
    end
    result
  end

  def self.needle_for_gauge(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    company = Snapshot.find(snapshot_id).company_id
    all_metrix_and_employees_in_group = calculate_inn_degree_email(snapshot_id, nil, company, NO_PIN, NO_GROUP)
    all_metrix = all_metrix_and_employees_in_group[0]
    emp_arr = all_metrix_and_employees_in_group[1]
    all_metrix_and_employees_off_group = calculate_outn_degree_email(snapshot_id, nil, company, NO_PIN, NO_GROUP)
    v_email_degs = sum_up_in_and_out_emails_for_company(all_metrix_and_employees_off_group, all_metrix, emp_arr)
    average_email_in_group = 0
    emp_arr = get_members_in_group(pid, gid, company)
    v_email_degs.each do |degree|
      average_email_in_group += degree[:measure].to_i if emp_arr.include?(degree[:id].to_i)
    end
    return average_email_in_group.to_f / emp_arr.count.to_f
  end

  def self.normalize(v_email_degs)
    (0..(v_email_degs.count - 1)).each do |grads|
      grade = v_email_degs[grads][:measure].to_f / v_email_degs.count.to_f
      v_email_degs[grads][:measure] = grade
    end
    v_email_degs
  end

  def self.sum_up_in_and_out_emails_for_company(all_out, all_in, emps)
    results = []
    emps.each do |emp|
      results.push(id: emp, measure: 0)
    end
    (0..(results.count - 1)).each do |emp|
      results[emp][:measure] = find_emp_in_array(results[emp][:id], all_out) + find_emp_in_array(results[emp][:id], all_in)
    end
    return results
  end

  def self.find_emp_in_array(id, all_in_out)
    res = 0
    all_in_out.each do |records|
      res += records[:measure].to_i if records[:id] == id
    end
    return res
  end

  def pre_calculate_information_isolate(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP)
    company = Snapshot.find(snapshot_id).company_id
    all_metrix_and_employees_in_group = calculate_inn_degree_email(snapshot_id, nil, company, pid, gid)
    all_metrix        = all_metrix_and_employees_in_group[0]
    emp_arr           = all_metrix_and_employees_in_group[1]

    all_metrix = sort_results(all_metrix)
    return [emp_arr, all_metrix, nil]
  end

  def self.return_harsh_quartile(matrixes)
    array = volume_json_to_array(matrixes)
    q1 = find_q1_max(array)
    iqr = find_q3_min(array) - find_q1_max(array)
    limit = q1 - 1.5 * iqr
    res = []
    matrixes.each do |mtrcs|
      res.push(mtrcs) if mtrcs[:measure] < limit
    end
    return res
  end

  def self.calculate_information_isolate_hidden_gauge(sid, nid, pid = NO_PIN, gid = NO_GROUP)
    result = calculate_information_isolate(sid, nid, pid, gid)
    return calculate_hidden_gauge_for_flag(result, sid, pid, gid)
  end

  def self.political_power_flag_hidden_gauge(sid, pid = NO_PIN, gid = NO_GROUP)
    result = political_power_flag(sid, pid, gid)
    result = result.each do |e|
      e[:measure] = e[:measure] > 0 ? 1 : 0
    end
    return calculate_hidden_gauge_for_flag(result, sid, pid, gid)
  end

  def self.calculate_hidden_gauge_for_flag(result, sid, pid, gid)
    company = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, company)
    group_id = (gid == -1 ? pid : gid)
    counter = 0
    result.each do |msure|
      counter += 1 if msure[:measure] == 1
    end
    return [{ group_id: group_id, measure: 0 }] if emps.count.to_f == 0
    return [{ group_id: group_id, measure: counter.to_f / emps.count.to_f }]
  end

  def self.calculate_information_isolate(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP)
    res = read_or_calculate_and_write("pre_calculate_information_isolate-#{snapshot_id}-#{network_id}-#{pid}-#{gid}") do
      emp_arr, all, advice = pre_calculate_information_isolate(snapshot_id, network_id, pid, gid)
      return [] if no_data_in_list?(all)
      return format_as_flag(return_harsh_quartile(all))
    end
    return res
  end

  def self.no_data_in_list?(l)
    return true if l.empty?
    return l.first[:measure] == l.last[:measure]
  end

  def format_as_flag(l)
    return l.each do |e|
      e[:measure] = 1
    end
  end

  def self.screen_only_members_in_group(pid, gid, company, all_res)
    emps = get_members_in_group(pid, gid, company)
    last_result = []
    all_res.each do |res|
      last_result.push(id: res[:id], measure: res[:measure]) if (emps.include?(res[:id].to_i) || emps.include?(res[:id].to_s)) && res[:measure] != 0
    end
    return last_result
  end

  def self.screen_only_members_in_group_for_gauge(pid, gid, company, all_res)
    emps = get_members_in_group(pid, gid, company)
    last_result = []
    all_res.each do |res|
      last_result.push(group_id: res[:group_id], measure: res[:measure]) if (emps.include?(res[:group_id].to_i) || emps.include?(res[:id].to_s)) && res[:measure] != 0
    end
    return last_result
  end

  def self.id_exists_in_results(array, item)
    found = false
    array.each do |it|
      found = true if it[:id] == item.to_i
    end
    return found
  end

  def self.find_higher_quartile(list)
    percentile = 5
    limit = nil
    limit = if list.count % percentile == 0
              (list.count / percentile)
            else
              ((list.count / percentile) - 1)
            end
    result = list.slice(list.count - limit.to_i, limit.to_i)
    result = add_employees_to_higher_quarter(list, result, find_min(result))
    result
  end

  def self.add_employees_to_higher_quarter(list, result, minimum)
    list.each do |empo|
      result.push(empo) if empo[:measure].to_i >= minimum && !exists_in_metrics(list, empo[:id].to_i)
    end
    return result
  end

  def self.find_min(arr)
    min = 0
    min = arr[0][:measure] unless arr.empty?
    arr.each do |obj|
      min = obj[:measure] if obj[:measure].to_i <= min
    end
    return min
  end

  def self.find_max(arr)
    max = 0
    max = arr[0][:measure] unless arr.empty?
    arr.each do |obj|
      max = obj[:measure] if obj[:measure].to_i > max
    end
    return max
  end

  def self.sort_results(matrix_column)
    res = []
    matrix_col = matrix_column
    until matrix_col.empty?
      if matrix_col.count == 1
        res.push(matrix_col[0])
        matrix_col.delete(matrix_col[0])
      else
        smallest = matrix_col[0] # find_first_item_not_sorted(matrix_col, res)
        matrix_col.each do |col|
          smallest = col if smallest.nil? || col[:measure] < smallest[:measure]
        end
        res.push(smallest)
        matrix_col.delete(smallest)
      end
    end
    return res
  end

  def self.find_first_item_not_sorted(matrix_col, res)
    result = nil
    (0..(matrix_col.count - 1)).each do |metric|
      result = matrix_col[metric] if !res.include?(matrix_col[metric]) && result.nil?
    end
    result
  end

  def self.grades_for_info_isolate(emp_arr, hashmap, stdev_in_e, av_in_e, av_out_a, stdev_out_a, out_advice)
    z_e = {}
    z_a = {}
    grades = []
    emp_arr.each do |emp|
      hashmap[emp.to_i] = 0 if hashmap[emp.to_i].nil?

      z_e[emp.to_i] = (hashmap[emp.to_i] - av_in_e) / stdev_in_e if stdev_in_e != 0
      z_a[emp.to_i] = (out_advice[emp.to_i] - av_out_a) / stdev_out_a if stdev_out_a != 0
      z_e[emp.to_i] = 0 if stdev_in_e == 0
      z_a[emp.to_i] = 0 if stdev_out_a == 0
      if z_e[emp.to_i] < -3 && z_a[emp.to_i] < 0
        grades.push(id: emp.to_i, measure: 1) # z_e[emp.to_i]
      end
    end
    return grades
  end

  def self.calculate_average_information_isolation(emp_ids, pid, gid, company)
    av_in_e = 0
    hashmap = {}
    emp_ids.uniq.each do |id|
      hashmap[id] = emp_ids.count(id)
      av_in_e += hashmap[id]
    end
    av_in_e = av_in_e.to_f / AlgorithmsHelper.get_members_in_group(pid, gid, company).count.to_f
    return [av_in_e, hashmap]
  end

  def self.calculate_standard_deviation(pid = NO_PIN, gid = NO_GROUP, av_in_e, hashmap, company)
    stdev_in_e = 0
    emp_arr = AlgorithmsHelper.get_members_in_group(pid, gid, company)
    emp_arr.each do |emp|
      stdev_in_e += (hashmap[emp.to_i].to_f - av_in_e) * (hashmap[emp.to_i].to_f - av_in_e) if hashmap[emp.to_i]
      stdev_in_e += (0.to_f - av_in_e) * (0.to_f - av_in_e) if hashmap[emp.to_i].nil?
    end
    stdev_in_e = stdev_in_e.to_f / AlgorithmsHelper.get_members_in_group(pid, gid, company).count.to_f
    stdev_in_e = Math.sqrt(stdev_in_e)
    return [stdev_in_e, emp_arr]
  end

  def self.exists_in_metrics(all_metrix, emp_id)
    res = false
    all_metrix.each do |metric|
      res = true if metric[:id].to_i == emp_id.to_i
    end
    return res
  end

  def self.calculate_inn_degree_email(snapshot_id, _network_id, company, pid = NO_PIN, gid = NO_GROUP)
    all_metrix = calc_indegree_for_all_matrix_in_relation_to_company(snapshot_id, gid, pid)
    emps = get_members_in_group(pid, gid, company)
    emps.each do |emp_id|
      all_metrix.push(id: emp_id.to_i, measure: 0) unless exists_in_metrics(all_metrix, emp_id)
    end
    return [all_metrix, emps]
  end

  def self.calculate_outn_degree_email(snapshot_id, _network_id, company, pid = NO_PIN, gid = NO_GROUP)
    all_metrix = calc_outdegree_for_all_matrix_in_relation_to_company(snapshot_id, gid, pid)
    emps = get_members_in_group(pid, gid, company)
    emps.each do |emp_id|
      all_metrix.push(id: emp_id.to_i, measure: 0) unless exists_in_metrics(all_metrix, emp_id)
    end
    return all_metrix
  end

  def self.remove_managers(employees_with_grades)
    result = []
    employees_with_grades.each do |emps|
      result.push(emps) if no_manager?(emps[:id].to_i)
    end
    result
  end

  def pre_calculate_powerful_non_managers(snapshot_id, network_id, network_b_id, network_c_id, pid = NO_PIN, gid = NO_GROUP)
    company = Snapshot.find(snapshot_id).company_id
    all_metrix_and_employees = calculate_inn_degree_email(snapshot_id, nil, company, pid, gid)
    emps_without_managers = remove_managers(all_metrix_and_employees[0])
    highest_emails = slice_percentile_from_hash_array(emps_without_managers, Q3)
    score_matrixes = calculate_quarters_for_powerful_non_managers(pid, gid, network_id, network_b_id, network_c_id, company, snapshot_id)
    score_matrixes.push(highest_emails)
    return [company, score_matrixes]
  end

  def self.screen_flat_distribution(highest_emails, sorted_results)
    # delete members that exist in both arrays
    to_remove = []
    sorted_results.each do |to_be_removed|
      to_remove.push to_be_removed if highest_emails.include?(to_be_removed)
    end
    to_remove.each do |rmv|
      sorted_results.delete rmv
    end
    highest_emails.each do |email|
      sorted_results.each do |has|
        highest_emails.delete(email) if has[:measure] == email[:measure]
      end
    end
    return highest_emails
  end

  def self.calculate_powerful_non_managers_hidden_gauge(snapshot_id, network_id, network_b_id, network_c_id, pid = NO_PIN, gid = NO_GROUP)
    company = Snapshot.find(snapshot_id).company_id
    results = calculate_powerful_non_managers(snapshot_id, network_id, network_b_id, network_c_id, pid, gid)
    emps = get_members_in_group(pid, gid, company)
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: 0 }] if emps.count == 0
    counter = 0
    results.each do |res|
      counter += 1 if res[:measure] == 1
    end
    return [{ group_id: group_id, measure: counter.to_f / emps.count.to_f }]
  end

  def self.calculate_powerful_non_managers(snapshot_id, network_id, network_b_id, network_c_id, pid = NO_PIN, gid = NO_GROUP)
    company, score_matrixes = read_or_calculate_and_write("pre_calculate_powerful_non_managers-#{snapshot_id}-#{network_id}-#{network_b_id}-#{network_c_id}-#{pid}-#{gid}") do
      pre_calculate_powerful_non_managers(snapshot_id, network_id, network_b_id, network_c_id, pid, gid)
    end
    results = assign_scores_by_all_categories(pid, gid, company, score_matrixes[0], score_matrixes[1], score_matrixes[2], score_matrixes[3])
    results
  end

  def self.calculate_quarters_for_powerful_non_managers(pid, gid, network_id, network_b_id, network_c_id, company, snapshot_id)
    company = find_company_by_snapshot(snapshot_id)
    advices_hash_table     = calculate_scores_for_network(snapshot_id, company, network_id,   pid, gid)
    trusts_hash_table      = calculate_scores_for_network(snapshot_id, company, network_b_id, pid, gid)
    friendships_hash_table = calculate_scores_for_network(snapshot_id, company, network_c_id, pid, gid)
    return [advices_hash_table, trusts_hash_table, friendships_hash_table]
  end

  ################################################################################################
  #
  # This function checks if emp appears in most lists provided, and
  # if he does then he is flagged.
  # If some of the lists are empty then they are not part of the count.
  # So:
  #   - if there are 4 networks then employees apearing in 4 or 3 networks will make the flag.
  #   - If there are less then 4 networks tnen only employees appearing in all will make the flag.
  #
  #################################################################################################
  def assign_scores_by_all_categories(pid, gid, company, z_e, advice_arr, trust_arr, friendship_arr)
    members_of_group = get_members_in_group(pid, gid, company)
    results = []
    populated_networks = 0
    populated_networks += 1 if z_e.count > 0
    populated_networks += 1 if advice_arr.count > 0
    populated_networks += 1 if trust_arr.count > 0
    populated_networks += 1 if friendship_arr.count > 0

    members_of_group.each do |mems|
      grade = 0
      grade += 1 if id_exists_in_results(advice_arr, mems.to_i)
      grade += 1 if id_exists_in_results(trust_arr, mems.to_i)
      grade += 1 if id_exists_in_results(friendship_arr, mems.to_i)
      grade += 1 if id_exists_in_results(z_e, mems.to_i)

      results.push(id: mems.to_i, measure: 1) if grade > (populated_networks.to_f / 2)
    end
    results
  end

  ############################################
  #
  # If there are no results in the network then return empty list
  # Otherwise return a list wit
  #
  ############################################
  def self.calculate_scores_for_network(snapshot_id, company, network_id, pid = NO_PIN, gid = NO_GROUP)
    raise "Network with ID: #{network_id} doesn not exist" if NetworkName.find(network_id).nil?

    members_of_group = get_members_in_group(pid, gid, company)
    return [] if NetworkSnapshotData.where(network_id: network_id, snapshot_id: snapshot_id).count == 0

    employees_for_network = []
    advice_grades = {}
    members_of_group.each do |mems|
      advice_grades[mems.to_i] = 0
    end
    results = NetworkSnapshotData.where(network_id: network_id, snapshot_id: snapshot_id, from_employee_id: members_of_group, to_employee_id: members_of_group)
    results.each do |network_grade|
      advice_grades[network_grade.to_employee_id] += 1 if network_grade.value == 1
    end
    in_degrees = []
    members_of_group.each do |grp|
      in_degrees.push(id: grp.to_i, measure: advice_grades[grp.to_i])
    end
    in_degrees = remove_managers(in_degrees)
    employees_for_network = slice_percentile_from_hash_array(in_degrees, Q3)
    employees_for_network
  end

  def self.calculate_pair_for_specific_relation_per_snapshot(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP)
    inner_select = AlgorithmsHelper.get_inner_select(pid, gid)
    snapshot = Snapshot.find(snapshot_id)
    dt = snapshot.timestamp.to_i
    query = AlgorithmsHelper.get_relation_arr(pid, gid, snapshot_id, network_id)
    unless inner_select.blank?
      query += " and from_employee_id in (#{inner_select} ) " \
      "and to_employee_id in (#{inner_select}) "
    end
    temp_res = ActiveRecord::Base.connection.select_all(query)
    return AlgorithmsHelper.format_to_analyze_algorithm(temp_res, dt)
  end

  def self.no_manager?(id)
    return EmployeeManagementRelation.where(manager_id: id).empty?
  end

  def get_most_social_worker(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP) ## need to convert
    company_id = Snapshot.where('id = ?', snapshot_id).first.company_id
    f_in_formatted = CdsSelectionHelper.format_from_activerecord_result(get_list_of_employees_in(snapshot_id, network_id, pid, gid)) # get full list of id: measure:
    all_emps_ids = get_all_emps(company_id, pid, gid)
    res = []
    friend_arr = []
    friend_pairs = AlgorithmsHelper.calculate_pair_for_specific_relation_per_snapshot(snapshot_id, network_id, pid, gid)
    friend_pairs.each do |pair| # produce array of indegree nodes for every node
      friend_arr[pair[:to_emp_id].to_i] = [] if friend_arr[pair[:to_emp_id].to_i].nil?
      friend_arr[pair[:to_emp_id].to_i].push(pair[:from_emp_id].to_i)
    end
    friend_arr.each_with_index do |from_members_arr, index|
      res << calc_social_per_friend_algorithm(f_in_formatted, from_members_arr, index) unless from_members_arr.nil?
    end
    (all_emps_ids - res.map { |emp| emp[:id] }).each { |emp| res << { id: emp, measure: 0.0 } }
    max = CdsUtilHelper.get_max(res)
    normalize_by_n_algorithm(res, max)
    res = res.sort_by { |h| -h[:measure] }
    return res
  end

  def normalize_by_n_algorithm(res, n)
    if n == 0
      res.each_with_index { |_e, i| (res[i][:measure] = n.round(2)) }
    else
      res.each_with_index { |_e, i| (res[i][:measure] = (res[i][:measure] / n).round(2)) } # replace every measure attribute in the array with its normalized value
    end
  end

  def calc_social_per_friend_algorithm(f_in, candidate_arr, friend_id)
    sum = 0
    count = 0
    avg_in = 0
    f_in.each do |entry|
      if candidate_arr.include?(entry[:id])
        sum += entry[:measure].to_i
        count += 1
      end
    end
    emp_fin = (f_in.select { |something| something[:id] == friend_id })[0][:measure].to_f
    avg_in = (sum / count.to_f) if count != 0
    return { id: friend_id, measure: Math.sqrt(emp_fin + avg_in) }
  end

  def most_isolated_workers(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP) ## need to convert
    res = get_friends_relation_in_network(snapshot_id, network_id, pid, gid)
    max = CdsUtilHelper.get_max(res)
    return res if max == -1
    res.each { |o| o[:measure] = max - o[:measure] }
    res = res.sort_by { |h| -h[:measure] }
    return res
  end

  def get_friends_relation_in_network(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP, in_or_out = 'in') ## need to convert
    company_id = AlgorithmsHelper.get_company_id(snapshot_id)
    f = if in_or_out == 'in'
          get_list_of_employees_in(snapshot_id, network_id, pid, gid)
        else
          get_list_of_employees_out(snapshot_id, network_id, pid, gid)
        end
    unit_size = CdsGroupsHelper.get_unit_size(company_id, pid, gid)
    f.rows.each do |row|
      val = if unit_size == 0
              0
            else
              row[MEASURE].to_f / unit_size
            end
      row[MEASURE] = val.round(2)
    end
    res = CdsSelectionHelper.format_from_activerecord_result(f)
    return res
  end

  def self.format_to_analyze_algorithm(ar, dt)
    ret = []
    ar.rows.each do |row|
      ret << { from_emp_id: row[ID].to_i, to_emp_id: row[MEASURE].to_i, weight: 1, dt: dt * 1000 }
    end
    return ret
  end

  ################################### Boolean network helper functions ##################################
  def get_array_of_employees_in(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP)
    res = get_list_of_employees_in(snapshot_id, network_id, pid, gid)
    sum_hash = is_sql_server_connection? ? '' : 'sum'
    res.as_json.map { |e| e[sum_hash].to_i }
  end

  def get_list_of_employees_in(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP)
    return get_list_of_employees_and_values(snapshot_id, NETWORK_IN, network_id, pid, gid)
  end

  def get_list_of_employees_out(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP)
    return get_list_of_employees_and_values(snapshot_id, NETWORK_OUT, network_id, pid, gid)
  end

  def get_list_of_employees_and_values(snapshot_id, groupby, network_id, pid = NO_PIN, gid = NO_GROUP)
    inner_select = AlgorithmsHelper.get_inner_select(pid, gid)
    query = "select #{groupby}, sum(value)  from network_snapshot_data " \
    "where snapshot_id = #{snapshot_id} AND network_id = #{network_id} "
    unless inner_select.blank?
      query += "and from_employee_id in (#{inner_select} ) " \
      "and to_employee_id in (#{inner_select}) "
    end
    query += " group by #{groupby} order by sum(value) desc"
    return ActiveRecord::Base.connection.select_all(query)
  end

  def get_hash_array_of_employees_out(sid, nid, pid = NO_PIN, gid = NO_GROUP)
    inner_select = AlgorithmsHelper.get_inner_select_with_company(pid, gid, sid)
    query = 'SELECT emps.id, sum(nsd.value) FROM network_snapshot_data as emps ' \
      'LEFT JOIN network_snapshot_data as nsd ON nsd.from_employee_id = emps.id '\
      'WHERE ' \
      "(nsd.snapshot_id = #{sid} OR nsd.snapshot_id IS NULL) AND "\
      "(nsd.network_id  = #{nid} OR nsd.network_id IS NULL) "
    unless inner_select.blank?
      query += " AND emps.id IN (#{inner_select}) AND "\
               "(nsd.to_employee_id IN (#{inner_select}) OR nsd.to_employee_id IS NULL) "
    end
    query += ' group by emps.id order by sum(nsd.value) desc'
    res = ActiveRecord::Base.connection.select_all(query)
    res.as_json.map { |e| { measure: e['sum'].to_i, id: e['from_employee_id'] } }
    return res
  end

  def self.get_relation_arr(_pid, _gid, snapshot, network_id)
    return "select from_employee_id, to_employee_id from network_snapshot_data where value = 1
    AND snapshot_id = #{snapshot} AND network_id = #{network_id}"
  end

  def get_all_emps(cid, pid, gid)
    if pid == NO_PIN && gid != NO_GROUP
      id = (gid.class == Fixnum) ? gid : gid.id
      group = Group.find(id)
      empsarr = group.extract_employees
      return empsarr
    end
    if pid != NO_PIN && gid == NO_GROUP
      return EmployeesPin.where(pin_id: pid).pluck(:employee_id)
    end
    if pid != NO_PIN && gid != NO_GROUP
      raise 'Ambiguous sub-group request with both pin-id and group-id'
    end
    return Employee.where(company_id: cid).pluck(:id)
  end

  ################################## ADVICE ##################################

  def create_advice_as_graph_algorithm(snapshot_id, cid, pid, gid, network_id)
    res = {}
    emp_from_list = []
    inner_select = AlgorithmsHelper.get_inner_select(pid, gid)
    query = "select from_employee_id, to_employee_id, value from network_snapshot_data where snapshot_id = #{snapshot_id} and value = 1 and network_id = #{network_id}"
    unless inner_select.nil?
      query += " and from_employee_id in (#{inner_select} ) " \
      "and to_employee_id in (#{inner_select}) "
    end
    partial_active_result = ActiveRecord::Base.connection.select_all(query)
    partial_active_result.rows.each do |row|
      if !emp_from_list.include?(row[0].to_i)
        res[row[0]] = []
        emp_from_list << row[0].to_i
      end
      res[row[0]] << row[1]
    end
    all_emps = get_all_emps(cid, pid, gid)
    remaining_emps = all_emps - emp_from_list
    remaining_emps.each do |emp_id|
      res[emp_id.to_s] = []
    end
    return { vertices: all_emps, adjacency_list: res }
  rescue => e
    puts e.message
    puts e.backtrace
  end

  def remove_employee_from_graph(graph, emp_id)
    graph_temp = graph.deep_dup
    vertices = graph_temp[:vertices]
    edges = graph_temp[:adjacency_list]
    vertices -= [emp_id]
    edges.each do |key, value|
      edges[key] = value - [emp_id.to_s]
    end
    edges.each do |key, _value|
      edges[key] = [] if key.to_s.eql?(emp_id.to_s)
    end
    { vertices: vertices, adjacency_list: edges }
  rescue => e
    puts e.message
    puts e.backtrace
  end

  def graph_connected?(graph)
    ans = true
    dfs = CdsDfsHelper::DFS.new(graph[:adjacency_list])
    vertices = graph[:vertices]
    vertices.each do |vertex|
      dfs.dfs_run!(vertex.to_s)
      ans = false if dfs.parent.keys.size != vertices.size
      dfs.parent = {}
    end
    return ans
  end

  def self.create_advise_matrix_per_snapshot(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP)
    res = []
    company_id = AlgorithmsHelper.get_company_id(snapshot_id)
    inner_select = CdsSelectionHelper.get_inner_select_as_arr(company_id, pid, gid)
    all_relations = NetworkSnapshotData.where(network_id: network_id, snapshot_id: snapshot_id, value: 1, from_employee_id: inner_select, to_employee_id: inner_select).select(:to_employee_id, :from_employee_id, :value)
    all_relations.each do |active_advise|
      res << { from: active_advise.value, to: active_advise.from_employee_id, value: 1 }
    end
    res = AlgorithmsHelper.remove_duplicate_advice(res)
    # add null relations
    all_possible_relations = inner_select.permutation(2).to_a
    # find if exist in already, else push them with value 0
    all_possible_relations.each do |rel_arr|
      possible_existing_relation = { from: rel_arr[0], to: rel_arr[1], value: 1 }
      res << { from: rel_arr[0], to: rel_arr[1], value: 0 } unless res.include? possible_existing_relation
    end
    res = res.sort { |a, b| [a[:from], a[:to]] <=> [b[:from], b[:to]] }
    return res
  end

  def calculate_pair_advices_per_snapshot(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP) ## need to convert
    return AlgorithmsHelper.calculate_pair_for_specific_relation_per_snapshot(snapshot_id, network_id, pid, gid)
  end

  def get_advice_in_avg(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP)
    company_id = AlgorithmsHelper.get_company_id(snapshot_id)
    sum = 0
    res = get_list_of_employees_in(snapshot_id, network_id, pid, gid)
    res.rows.each do |row|
      sum += row[MEASURE].to_i
    end
    unit_size = CdsGroupsHelper.get_unit_size(company_id, pid, gid)
    raise 'No Employees found!' if unit_size == 0
    return (sum.to_f / unit_size.to_f).round(2)
  end

  def get_advice_relation_in_network(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP, in_or_out = 'in') ## need to convert
    company_id = AlgorithmsHelper.get_company_id(snapshot_id)
    a = if in_or_out == 'in'
          get_list_of_employees_in(snapshot_id, network_id, pid, gid)
        else
          get_list_of_employees_out(snapshot_id, network_id, pid, gid)
        end
    unit_size = CdsGroupsHelper.get_unit_size(company_id, pid, gid)
    raise 'No Employees found!' if unit_size == 0
    a.rows.each do |row|
      val = row[MEASURE].to_f / unit_size
      row[MEASURE] = val.round(2)
    end
    res = CdsSelectionHelper.format_from_activerecord_result(a)
    return res
  end

  def find_most_expert_worker(snapshotid, pinid, gid, network_id) ## need to convert
    get_advice_relation_in_network(snapshotid, network_id, pinid, gid, 'in').sort_by { |k| k[:measure] }.reverse
  end

  def self.remove_duplicate_advice(advice_matrix)
    advice_matrix.uniq
  end

  def self.get_inner_select(pinid, gid)
    return CdsGroupsHelper.get_inner_select_by_group(gid) if pinid == NO_PIN && gid != NO_GROUP
    return CdsPinsHelper.get_inner_select_by_pin(pinid) if pinid != NO_PIN && gid == NO_GROUP
    raise 'Ambiguous sub-group request with both pin-id and group-id' if pinid != NO_PIN && gid != NO_GROUP
    return nil
  end

  def self.get_inner_select_with_company(pid, gid, sid)
    return CdsGroupsHelper.get_inner_select_by_group(gid) if pid == NO_PIN && gid != NO_GROUP
    return CdsPinsHelper.get_inner_select_by_pin(pinid) if pid != NO_PIN && gid == NO_GROUP
    raise 'Ambiguous sub-group request with both pin-id and group-id' if pid != NO_PIN && gid != NO_GROUP
    cid = Snapshot.find(sid).company_id
    mems = get_members_in_group(pid, gid, cid).join(',')
    return mems
  end

  def self.get_members_in_group(pinid, gid, company_id)
    return Group.find(gid).extract_employees if pinid == NO_PIN && gid != NO_GROUP
    return CdsPinsHelper.get_inner_select_by_pin_as_arr(pinid) if pinid != NO_PIN && gid == NO_GROUP
    if pinid == NO_PIN && gid == NO_GROUP
      return Company.find(company_id).active_employees.pluck(:id)
    end
    return nil
  end

  def self.get_members_not_in_group(emps, company_id)
    return get_members_in_group(-1, -1, company_id) - emps unless emps.nil?
    return get_members_in_group(-1, -1, company_id)
  end
  ####################################### FLAGS ##############################################3

  def get_likely_to_leave_flag(network_a_id, network_f_id, snapshot_id, pid = NO_PIN, gid = NO_GROUP) # #need to convert
    res_a = []
    res_f = []
    avg_a_in = get_advice_in_avg(snapshot_id, network_a_id, pid, gid)
    a = CdsSelectionHelper.format_from_activerecord_result(get_list_of_employees_in(snapshot_id, network_a_id, pid, gid))
    f = get_friends_relation_in_network(snapshot_id, network_f_id, pid, gid, 'in')
    a.each do |candidate|
      res_a << { id: candidate[:id] } if candidate[:measure].to_f > avg_a_in
    end
    f.each do |candidate|
      res_f << { id: candidate[:id] } if candidate[:measure] == 0
    end
    intersection = res_a & res_f
    return intersection
  end

  def most_promising_worker(company_id, snapshot_id, network_f_id, network_b_id, pid = NO_PIN, gid = NO_GROUP) ## need to convert
    max_size = 10
    advisors = CdsSelectionHelper.format_from_activerecord_result(get_list_of_employees_in(snapshot_id, network_b_id, pid, gid))
    advisors = advisors.each { |node| node[:measure] = node[:measure].to_i } ## hack to convert measure values to integers
    advisors = advisors.sort_by { |k| k[:measure] }.reverse ## if a_in_n isn't sorted
    socials = get_most_social_worker(snapshot_id, network_f_id, pid, gid)
    group_or_pin_size = CdsGroupsHelper.get_unit_size(company_id, pid, gid)
    potential_candidates_size = group_or_pin_size > max_size ? max_size : group_or_pin_size
    s = socials[0..potential_candidates_size - 1].map { |elem| elem.except(:measure) } ## remove measure attribute from hashes
    a = advisors[0..potential_candidates_size - 1].map { |elem| elem.except(:measure) }
    intersected = s & a
    return intersected
  end

  def most_bypassed_managers(company_id, snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP) ## need to convert
    max_size = 5
    informal_matrix = CdsEmployeeManagementRelationHelper.create_informal_matrix_per_snapshot(snapshot_id, network_id, pid, gid)
    bypassed_managers = CdsEmployeeManagementRelationHelper.get_bypassed_in(informal_matrix, company_id, pid, gid)
    potential_candidates_size = bypassed_managers.length > max_size ? max_size : bypassed_managers.length
    res = if potential_candidates_size != 0
            bypassed_managers[0..potential_candidates_size - 1].map { |elem| elem.except(:measure) }
          else
            []
          end
    return res
  end

  def team_glue_algorithm(company_id, snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP) ## need to convert
    res = []
    graph = create_advice_as_graph_algorithm(snapshot_id, company_id, pid, gid, network_id)
    return res unless graph_connected?(graph)
    graph[:vertices].each do |emp_id|
      ans = false
      temp_graph = remove_employee_from_graph(graph, emp_id)
      dfs = CdsDfsHelper::DFS.new(temp_graph[:adjacency_list])
      vertices = graph[:vertices] - [emp_id]
      vertices.each do |vertex|
        dfs.dfs_run!(vertex.to_s)
        ans = true if dfs.parent.keys.size != vertices.size
        dfs.parent = {}
      end
      res << { id: emp_id } if ans == true
    end
    res
  end

  ########################################## TRUST ######################################

  def get_trust_in_network(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP) ## need to convert
    t_in = get_list_of_employees_and_values(snapshot_id, NETWORK_IN, network_id, pid, gid)
    return format_trust_scores(t_in, snapshot_id, pid, gid)
  end

  def get_trust_out_network(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP) ## need to convert
    t_out = get_list_of_employees_and_values(snapshot_id, NETWORK_OUT, network_id, pid, gid)
    return format_trust_scores(t_out, snapshot_id, pid, gid)
  end

  ################################################## Gauges #############################################

  #################################################################################
  # 1 - Get indegree vecotr of employees in network nid
  # 2 - Get maximum indegree from that vector
  # 3 - Set n to be the number of employees in the group
  # 4 - pad the array with zeros
  # 5 - Return sum of differences of max indegree from employees indegrees divieded
  #     by theoretical maximum sum of such differences.
  #     See "Freeman Centralization"
  #################################################################################
  def centrality_boolean_matrix(sid, gid, pid, nid)
    cid = find_company_by_snapshot(sid)
    a_indegs = get_array_of_employees_in(sid, nid, pid, gid)
    s_max_indegs = a_indegs.max.nil? ? 0 : a_indegs.max
    n = get_all_emps(cid, pid, gid).count
    return 0.0 if n <= 2
    a_indegs += Array.new(n - a_indegs.count, 0)
    sum = 0
    a_indegs.each { |in_i| sum += (s_max_indegs - in_i) }
    return sum.to_f / ((n - 1) * (n - 2))
  end

  #################################################################################
  # Similar to centrality_boolean_matrix, only working on the emails network
  #################################################################################
  def centrality_numeric_matrix(sid, gid, pid)
    cid = find_company_by_snapshot(sid)
    a_indegs = calc_indegree_for_all_matrix(sid, gid, pid).map { |elm| elm[:measure] }
    s_max_indegs = a_indegs.max.nil? ? 0 : a_indegs.max
    n = get_all_emps(cid, pid, gid).count
    return 0.0 if n <= 2
    a_indegs += Array.new(n - a_indegs.count, 0)
    sum = 0
    a_indegs.each { |in_i| sum += (s_max_indegs - in_i) }
    denominator = ((n - 1) * (n - 2) * s_max_indegs)
    return (sum.to_f / denominator)
  end

  def self.centrality_of_two_boolean_networks(sid, gid, pid, nid1, nid2)
    nid1_centrality_squared = centrality_boolean_matrix(sid, gid, pid, nid1)**2
    nid2_centrality_squared = centrality_boolean_matrix(sid, gid, pid, nid2)**2
    res = Math.sqrt(nid1_centrality_squared + nid2_centrality_squared).round(3)
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: res }]
  end

  def self.centrality_of_emails_and_boolean_networks(sid, gid, pid, nid1)
    nid1_centrality_squared  = centrality_boolean_matrix(sid, gid, pid, nid1)**2
    email_centrality_squared = centrality_numeric_matrix(sid, gid, pid)**2
    res = Math.sqrt(nid1_centrality_squared + email_centrality_squared).round(3)
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: res }]
  end

  #################################################################################
  ##
  ## Describes the overall level of internal collaboration in the group.
  ## It does so by calculating the proportion of existing ties in the networks
  ## from all possible ties.
  ##
  ## The algorithm works on emails and any other network
  ##
  #################################################################################
  def self.density_of_email_network(sid, gid, pid, nid)
    cid = find_company_by_snapshot(sid)
    n = get_all_emps(cid, pid, gid).count
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: 0.0 }] if n <= 3

    s_max_email_traffic   = s_calc_max_traffic_between_two_employees(sid, gid, pid)
    s_sum_traffic_emails  = s_calc_sum_of_metrix(sid, gid, pid)
    s_sum_traffic_network = s_calc_sum_of_metrix(sid, gid, pid, nid)

    email_density   = s_max_email_traffic.nil? ? 0 : (s_sum_traffic_emails.to_f / (n * (n - 1) * s_max_email_traffic))
    network_density = (s_sum_traffic_network.to_f / (n * (n - 1)))

    res = Math.sqrt(email_density**2 + network_density**2).round(3)
    return [{ group_id: group_id, measure: res }]
  end

  def self.calculate_gauge_parameters(cid, aid, sid, company_metric_id)
    v_gauge_values = retrieve_gauge_values(cid, aid, sid, company_metric_id)
    min_range = v_gauge_values.empty? ? -1 : v_gauge_values.min
    max_range = v_gauge_values.empty? ? -1 : v_gauge_values.max
    min_range_wanted = v_gauge_values.empty? ? -1 : find_q1_max(v_gauge_values)
    max_range_wanted = v_gauge_values.empty? ? -1 : find_q3_min(v_gauge_values)
    res = {
      min_range: min_range,
      min_range_wanted: min_range_wanted,
      max_range: max_range,
      max_range_wanted: max_range_wanted
    }
    return res
  end

  def self.retrieve_gauge_values(cid, aid, sid, cmid)
    return CdsMetricScore.where(company_id: cid, algorithm_id: aid, snapshot_id: sid, company_metric_id: cmid).where.not(score: nil).pluck(:score)
  end

  ##################### new explore metrics for old flags etc #########################

  def self.assign_same_score_to_all_emps(sid, gid = NO_GROUP, pid = NO_PIN)
    a_emps = if gid != NO_GROUP
               Group.find(gid).extract_employees
             elsif pid != NO_PIN
               EmployeesPin.where(pin_id: pid).pluck(:employee_id)
             else
               Employee.where(company_id: find_company_by_snapshot(sid)).pluck(:id)
             end
    return a_emps.map { |eid| { id: eid, measure: 1 } }
  end

  def self.density_of_network(sid, gid, pid, nid, nid_2)
    cid = find_company_by_snapshot(sid)
    n = get_all_emps(cid, pid, gid).count
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: 0.0 }] if n <= 3

    s_sum_traffic_network = s_calc_sum_of_metrix(sid, gid, pid, nid)
    s_sum_traffic_second_network = s_calc_sum_of_metrix(sid, gid, pid, nid_2)

    network_density = (s_sum_traffic_network.to_f / (n * (n - 1)))
    sec_network_density = (s_sum_traffic_second_network.to_f / (n * (n - 1)))
    res = Math.sqrt(sec_network_density**2 + network_density**2).round(3)
    return [{ group_id: group_id, measure: res }]
  end

  ################################################## EMAIL #############################################

  def centrality_algorithm(snapshot_id, group_id, pin_id)
    res = calc_normalized_indegree_for_all_matrix(snapshot_id, group_id, pin_id)
    return res.sort_by { |item| item[:measure] }.reverse if res != -1
    return []
  end

  def central_algorithm(snapshot_id, group_id, pin_id)
    res = calc_normalized_indegree_for_to_matrix(snapshot_id, group_id, pin_id)
    return res.sort_by { |item| item[:measure] }.reverse if res != -1
    return []
  end

  def in_the_loop_algorithm(snapshot_id, group_id, pin_id)
    res = calc_normalized_indegree_for_cc_matrix(snapshot_id, group_id, pin_id)
    return res.sort_by { |item| item[:measure] }.reverse if res != -1
    return []
  end

  def political_power_flag(sid, pid, gid)
    res = read_or_calculate_and_write("political_power_flag-#{sid}-#{pid}-#{gid}") do
      cid = find_company_by_snapshot(sid)
      #inner_select = get_inner_select_as_arr(cid, pid, gid)
      emps = get_members_in_group(pid, gid, cid)
      return [] if emps.nil? || emps.empty?
      network = NetworkSnapshotData.emails(cid)
      sqlstrdenom = "SELECT COUNT(id) AS bcc_count, to_employee_id
                      FROM network_snapshot_data
                      WHERE to_type         = 3
                      AND to_employee_id    IN (#{emps.join(',')})
                      AND from_employee_id  IN (#{emps.join(',')})
                      AND network_id        = #{network}
                      AND snapshot_id       = #{sid}
                      GROUP BY to_employee_id"
      bcc = ActiveRecord::Base.connection.select_all(sqlstrdenom).to_hash

      sqlstrnumer = "SELECT COUNT(id) AS all_count, to_employee_id
                      FROM network_snapshot_data
                      WHERE to_employee_id  IN (#{emps.join(',')})
                      AND from_employee_id  IN (#{emps.join(',')})
                      AND network_id        = #{network}
                      AND snapshot_id       = #{sid}
                      GROUP BY to_employee_id"
      all = ActiveRecord::Base.connection.select_all(sqlstrnumer).to_hash

      bcc_hash = {}
      bcc.each { |e| bcc_hash[e['to_employee_id']] = e['bcc_count'] }

      h_scores = {}
      all.each do |r|
        next if r['all_count'] == 0
        bcc_count = bcc_hash[r['to_employee_id']].nil? ? 0 : bcc_hash[r['to_employee_id']]
        h_scores[r['to_employee_id']] = bcc_count.to_f / r['all_count'].to_f
      end

      res = AlgorithmsHelper.harsh_idscore_to_upperlower_quartile_emp_ids(h_scores, emps)
      res.each { |e| e[:measure] = e[:score] }
      return res
    end
    return res
  end

  def total_activity_centrality_algorithm(snapshot_id, group_id, pin_id)
    res = calc_normalized_outdegree_for_all_matrix(snapshot_id, group_id, pin_id)
    return res.sort_by { |item| item[:measure] }.reverse if res != -1
    return []
  end

  def delegator_algorithm(snapshot_id, group_id, pin_id)
    res = calc_normalized_outdegree_for_to_matrix(snapshot_id, group_id, pin_id)
    return res.sort_by { |item| item[:measure] }.reverse if res != -1
    return []
  end

  def knowledge_distributor_algorithm(snapshot_id, group_id, pin_id)
    res = calc_normalized_outdegree_for_cc_matrix(snapshot_id, group_id, pin_id)
    return res.sort_by { |item| item[:measure] }.reverse if res != -1
    return []
  end

  def politically_active_algorithm(snapshot_id, group_id, pin_id)
    res = calc_normalized_outdegree_for_bcc_matrix(snapshot_id, group_id, pin_id)
    return res.sort_by { |item| item[:measure] }.reverse if res != -1
    return []
  end

  def calc_indegree_for_all_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_all_matrix(snapshot_id, EMAILS_IN, group_id, pin_id)
  end

  def calc_indegree_for_all_matrix_in_relation_to_company(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_all_matrix(snapshot_id, EMAILS_IN, group_id, pin_id)
  end

  def calc_outdegree_for_all_matrix_in_relation_to_company(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_all_matrix(snapshot_id, EMAILS_OUT, group_id, pin_id)
  end

  def calc_outdegree_for_all_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_all_matrix(snapshot_id, EMAILS_OUT, group_id, pin_id)
  end

  def calc_max_outdegree_for_all_matrix(snapshot_id)
    result_vector = calc_outdegree_for_all_matrix(snapshot_id, -1, -1)
    calc_max_vector(result_vector)
  end

  def calc_max_indegree_for_all_matrix(snapshot_id)
    result_vector = calc_indegree_for_all_matrix(snapshot_id, -1, -1)
    calc_max_vector(result_vector)
  end

  def calc_avgout_degree_for_all_matrix(snapshot_id)
    result_vector = calc_outdegree_for_all_matrix(snapshot_id, -1, -1)
    comp1 = find_company_by_snapshot(snapshot_id)
    company_size = CdsGroupsHelper.get_unit_size(comp1, -1, -1)
    total_sum = result_vector.inject(0) { |m, e| m + e[:measure] }
    return -1 if company_size == 0
    (total_sum.to_f / company_size).round(2)
  end

  def calc_normalized_indegree_for_all_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_all_matrix(snapshot_id, EMAILS_IN, group_id, pin_id)
  end

  def calc_normalized_outdegree_for_all_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_all_matrix(snapshot_id, EMAILS_OUT, group_id, pin_id)
  end

  def calc_indegree_for_to_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_indeg_for_specified_matrix(snapshot_id, TO_MATRIX, group_id, pin_id)
  end

  def calc_indegree_for_bcc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_indeg_for_specified_matrix(snapshot_id, BCC_MATRIX, group_id, pin_id)
  end

  def calc_outdegree_for_to_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_outdeg_for_specified_matrix(snapshot_id, TO_MATRIX, group_id, pin_id)
  end

  def calc_outdegree_for_cc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_outdeg_for_specified_matrix(snapshot_id, CC_MATRIX, group_id, pin_id)
  end

  def calc_outdegree_for_bcc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_outdeg_for_specified_matrix(snapshot_id, BCC_MATRIX, group_id, pin_id)
  end

  def calc_avgout_degree_for_to_matrix(snapshot_id)
    calc_avg_outdeg_for_specified_matrix(snapshot_id, TO_MATRIX)
  end

  def calc_avgout_degree_for_cc_matrix(snapshot_id)
    calc_avg_outdeg_for_specified_matrix(snapshot_id, CC_MATRIX)
  end

  def calc_avgout_degree_for_bcc_matrix(snapshot_id)
    calc_avg_outdeg_for_specified_matrix(snapshot_id, BCC_MATRIX)
  end

  def calc_avgin_degree_for_to_matrix(snapshot_id)
    calc_avg_indeg_for_specified_matrix(snapshot_id, TO_MATRIX)
  end

  def calc_avgin_degree_for_cc_matrix(snapshot_id)
    calc_avg_indeg_for_specified_matrix(snapshot_id, CC_MATRIX)
  end

  def calc_avgin_degree_for_bcc_matrix(snapshot_id)
    calc_avg_indeg_for_specified_matrix(snapshot_id, BCC_MATRIX)
  end

  def calc_normalized_indegree_for_to_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, TO_MATRIX, EMAILS_IN, group_id, pin_id)
  end

  def calc_normalized_indegree_for_cc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, CC_MATRIX, EMAILS_IN, group_id, pin_id)
  end

  def calc_normalized_indegree_for_bcc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, BCC_MATRIX, EMAILS_IN, group_id, pin_id)
  end

  def calc_normalized_outdegree_for_to_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, TO_MATRIX, EMAILS_OUT, group_id, pin_id)
  end

  def calc_normalized_outdegree_for_cc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, CC_MATRIX, EMAILS_OUT, group_id, pin_id)
  end

  def calc_normalized_outdegree_for_bcc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, BCC_MATRIX, EMAILS_OUT, group_id, pin_id)
  end

  def self.s_calc_max_traffic_between_two_employees(sid, gid = NO_GROUP, pid = NO_PIN)
    res = h_calc_max_traffic_between_two_employees_with_ids(sid, gid, pid)
    return nil if res.nil? || res.empty?
    return res[:max].to_i
  end

  def self.h_calc_max_traffic_between_two_employees_with_ids(sid, gid = NO_GROUP, pid = NO_PIN)
    cid = find_company_by_snapshot(sid)
    emps = get_members_in_group(pid, gid, cid).sort
    return [] if emps.count == 0
    empsstr = emps.join(',')
    network = NetworkSnapshotData.emails(cid)
    sqlstr = "SELECT outter_nsd.from_employee_id, outter_nsd.to_employee_id, COUNT(id) AS maximum_traffic
              FROM network_snapshot_data    AS outter_nsd
              WHERE outter_nsd.snapshot_id      = #{sid}
              AND   network_id                  = #{network}
              AND   outter_nsd.to_employee_id   IN (#{empsstr})
              AND   outter_nsd.from_employee_id IN (#{empsstr}) 
              AND   outter_nsd.from_employee_id <> outter_nsd.to_employee_id
              GROUP BY outter_nsd.from_employee_id, outter_nsd.to_employee_id
              HAVING 	COUNT(id) = (
                SELECT MAX(emailsum)          AS maxi
                FROM (SELECT COUNT(id)        AS emailsum 
                  FROM network_snapshot_data  AS inner_nsd
              	  WHERE inner_nsd.snapshot_id       = #{sid} 
                  AND   network_id                  = #{network}
                  AND   inner_nsd.to_employee_id    IN (#{empsstr}) 
                  AND   inner_nsd.from_employee_id  IN (#{empsstr}) 
                  AND   inner_nsd.from_employee_id <> inner_nsd.to_employee_id
              	  GROUP BY inner_nsd.from_employee_id, inner_nsd.to_employee_id) AS innercount)"

    max_traffic = ActiveRecord::Base.connection.exec_query(sqlstr)
    h_max_traffic = max_traffic.to_hash[0]

    return nil if h_max_traffic.nil?
    return {
      from: h_max_traffic['from_employee_id'],
      to:   h_max_traffic['to_employee_id'],
      max:  h_max_traffic['maximum_traffic']
    }
  end

  def self.s_calc_sum_of_metrix(sid, gid = NO_GROUP, pid = NO_PIN, nid = NO_NETWORK)
    cid = find_company_by_snapshot(sid)
    emps = get_members_in_group(pid, gid, cid).sort
    return [] if emps.count == 0
    empsstr = emps.join(',')
    sqlstr = "SELECT COUNT(id) 
              FROM network_snapshot_data 
              WHERE snapshot_id       = #{sid} 
              AND network_id          = #{nid}
              AND from_employee_id IN  (#{empsstr}) 
              AND to_employee_id   IN  (#{empsstr})
              AND value               = 1"

    res = ActiveRecord::Base.connection.exec_query(sqlstr)
    sum_hash = is_sql_server_connection? ? '' : 'count'
    return res[0][sum_hash].to_i
  end
  ############################ ALL MATRIX IMPLEMENTATION #########################################

  def calc_degree_for_all_matrix(snapshot_id, direction, group_id = NO_GROUP, pin_id = NO_PIN)
    res = []
    emp_list = []
    if direction == EMAILS_IN
      to_degree = calc_indeg_for_specified_matrix(snapshot_id, TO_MATRIX, group_id, pin_id)
      cc_degree = calc_indeg_for_specified_matrix(snapshot_id, CC_MATRIX, group_id, pin_id)
      bcc_degree = calc_indeg_for_specified_matrix(snapshot_id, BCC_MATRIX, group_id, pin_id)
    else
      to_degree = calc_outdeg_for_specified_matrix(snapshot_id, TO_MATRIX, group_id, pin_id)
      cc_degree = calc_outdeg_for_specified_matrix(snapshot_id, CC_MATRIX, group_id, pin_id)
      bcc_degree = calc_outdeg_for_specified_matrix(snapshot_id, BCC_MATRIX, group_id, pin_id)
    end
    union = to_degree + cc_degree + bcc_degree
    union.each do |entry|
      res[entry[:id]] = 0 if res[entry[:id]].nil?
      res[entry[:id]] += entry[:measure]
    end
    res.each_with_index { |entry, index| emp_list << { id: index, measure: entry } unless entry.nil? }
    emp_list
  end

  def calc_normalized_degree_for_all_matrix(snapshot_id, direction, group_id = NO_GROUP, pin_id = NO_PIN)
    res = (direction == EMAILS_IN) ? calc_indegree_for_all_matrix(snapshot_id, group_id, pin_id) : calc_outdegree_for_all_matrix(snapshot_id, group_id, pin_id)
    maximum = (direction == EMAILS_IN) ? calc_max_indegree_for_all_matrix(snapshot_id) : calc_max_outdegree_for_all_matrix(snapshot_id)
    return res if maximum == 0
    return -1 if maximum.nil?
    res.map { |emp| { id: emp[:id], measure: (emp[:measure] /= maximum.to_f).round(2) } }
  end

  def calc_degree_for_specified_matrix_with_relation_to_company(snapshot_id, matrix_name, direction, group_id = NO_GROUP, pin_id = NO_PIN)
    res = []
    company = find_company_by_snapshot(snapshot_id)
    inner_select = CdsSelectionHelper.get_inner_select_as_arr(company, pin_id, group_id)
    current_snapshot_nodes = NetworkSnapshotData.emails(company).where(snapshot_id: snapshot_id)
    if direction == EMAILS_IN
      if matrix_name == 4
        current_snapshot_nodes = current_snapshot_nodes.where(to_employee_id: inner_select, from_employee_id:
        inner_select).select("#{direction} as id, count(id) as total_sum").group(direction)
      else
        current_snapshot_nodes = current_snapshot_nodes.where(to_employee_id: inner_select, from_employee_id:
        inner_select, to_type: matrix_name).select("#{direction} as id, count(id) as total_sum").group(direction)
      end
    elsif direction == EMAILS_OUT
      if matrix_name == 4
        current_snapshot_nodes = current_snapshot_nodes.where(to_employee_id: inner_select, from_employee_id:
        inner_select).select("#{direction} as id, count(id) as total_sum").group(direction)
      else
        current_snapshot_nodes = current_snapshot_nodes.where(to_employee_id: inner_select, from_employee_id:
        inner_select, to_type: matrix_name).select("#{direction} as id, count(id) as total_sum").group(direction)
      end
    end
    current_snapshot_nodes.each do |emp|
      res << { id: emp.id, measure: emp.total_sum }
    end
    return res
  end

  def calc_indeg_for_specified_matrix_relation_to_company(snapshot_id, matrix_name, group_id = NO_GROUP, pin_id = NO_PIN)
    return calc_degree_for_specified_matrix_with_relation_to_company(snapshot_id, matrix_name, EMAILS_IN, group_id, pin_id)
  end

  def calc_outdeg_for_specified_matrix(snapshot_id, matrix_name, group_id = NO_GROUP, pin_id = NO_PIN)
    return calc_degree_for_specified_matrix(snapshot_id, matrix_name, EMAILS_OUT, group_id, pin_id)
  end

  def calc_outdeg_for_specified_matrix_relation_to_company(snapshot_id, matrix_name, group_id = NO_GROUP, pin_id = NO_PIN)
    return calc_degree_for_specified_matrix_with_relation_to_company(snapshot_id, matrix_name, EMAILS_OUT, group_id, pin_id)
  end

  def calc_normalized_degree_for_specified_matrix(snapshot_id, matrix_name, direction, group_id = NO_GROUP, pin_id = NO_PIN)
    res = calc_degree_for_specified_matrix(snapshot_id, matrix_name, direction, group_id, pin_id)
    maximum = calc_max_degree_for_specified_matrix(snapshot_id, matrix_name, direction)
    return res if maximum == 0
    return -1 if maximum.nil?
    res.map { |emp| { id: emp[:id], measure: (emp[:measure] /= maximum.to_f).round(2) } }
  end

  def calc_normalized_indegree_for_specified_matrix(snapshot_id, matrix_name, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, matrix_name, EMAILS_IN, group_id, pin_id)
  end

  def calc_normalized_outdegree_for_specified_matrix(snapshot_id, matrix_name, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, matrix_name, EMAILS_OUT, group_id, pin_id)
  end

  #################################  AVERAGES #######################################################
  def calc_avg_deg_for_specified_matrix(snapshot_id, matrix_name, direction)
    result_vector = nil
    if (direction == EMAILS_IN)
      result_vector = calc_indeg_for_specified_matrix(snapshot_id, matrix_name, -1, -1)
    else
      result_vector = calc_outdeg_for_specified_matrix(snapshot_id, matrix_name, -1, -1)
    end

    comp1 = find_company_by_snapshot(snapshot_id)
    company_size = CdsGroupsHelper.get_unit_size(comp1, -1, -1)
    total_sum = result_vector.inject(0) { |memo, emp| memo + emp[:measure] }
    return -1 if company_size == 0
    (total_sum.to_f / company_size).round(2)
  end

  def calc_avg_indeg_for_specified_matrix(snapshot_id, matrix_name)
    calc_avg_deg_for_specified_matrix(snapshot_id, matrix_name, EMAILS_IN)
  end

  def calc_avg_outdeg_for_specified_matrix(snapshot_id, matrix_name)
    calc_avg_deg_for_specified_matrix(snapshot_id, matrix_name, EMAILS_OUT)
  end

  #################################  MAXIMA FUNCTIONS ################################################
  def calc_max_degree_for_specified_matrix(snapshot_id, matrix_name, direction)
    res = nil
    if (direction == EMAILS_IN)
      res = calc_max_indegree_for_specified_matrix(snapshot_id, matrix_name)
    else
      res = calc_max_outdegree_for_specified_matrix(snapshot_id, matrix_name)
    end
    return res
  end

  def calc_max_indegree_for_specified_matrix(snapshot_id, matrix_name)
    result_vector = calc_indeg_for_specified_matrix(snapshot_id, matrix_name, -1, -1)
    calc_max_vector(result_vector)
  end

  def calc_max_outdegree_for_specified_matrix(snapshot_id, matrix_name)
    result_vector = calc_outdeg_for_specified_matrix(snapshot_id, matrix_name, -1, -1)
    calc_max_vector(result_vector)
  end

  def calc_max_vector(emp_vector)
    return calc_max_in_vector_by_attribute(emp_vector, :measure)
  end

  def calc_max_in_vector_by_attribute(emp_vector, attribute)
    return emp_vector.map { |elem| elem[attribute.to_s.to_sym] }.max
  end

  #================================ GROUP MEASURES ===========================================

  def self.calculate_communication_dynamics(gid, sid)
    return [] if gid == -1
    selected_group = Group.find(gid)
    return [] if selected_group[:parent_group_id].nil?
    sid = Snapshot.find(sid).id
    company = find_company_by_snapshot(sid)    
    groups = Group.where(parent_group_id: selected_group[:parent_group_id])
    network = NetworkSnapshotData.emails(company)
    snapshot_emails = NetworkSnapshotData.where(network_id: network, snapshot_id: sid)
    communications = []
    result = []
    sum = 0
    groups.each do |gr|
      score = if gr.id == selected_group.id
                snapshot_emails
                  .where(from_employee_id: selected_group.extract_employees, to_employee_id: selected_group.extract_employees).count
              else
                emails_to = snapshot_emails.where(from_employee_id: selected_group.extract_employees, to_employee_id: gr.extract_employees)
                emails_from = snapshot_emails.where(to_employee_id: selected_group.extract_employees, from_employee_id: gr.extract_employees)
                (emails_to + emails_from).count
              end
      communications << { id: gr[:id], measure: score }
      sum += score
    end

    external_emails = OverlaySnapshotData.number_connected_to_group(sid, gid, OverlayEntityType.find_by(overlay_entity_type: 'external_domain').id)
    communications << { id: 0, measure: external_emails }
    sum += external_emails
    communications = communications.map { |o| { id: o[:id], measure: sum == 0 ? 0 : (o[:measure].to_f / sum) * 100 } }
    return communications if communications.size <= 5
    distract = 0
    (1..4).each do |_|
      max = communications.max_by { |o| o[:measure] }
      communications = communications.reject { |o| o[:id] == max[:id] }
      result.push << max
      distract += max[:measure]
    end
    result.push(id: -1, measure: 100 - distract)
    result
  end

  private

  def format_trust_scores(t, snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    company_id = AlgorithmsHelper.get_company_id(snapshot_id)
    unit_size = CdsGroupsHelper.get_unit_size(company_id, pid, gid)
    raise 'No Employees found!' if unit_size == 0
    t.rows.each do |row|
      val = row[MEASURE].to_f / unit_size
      row[MEASURE] = val.round(2)
    end
    CdsSelectionHelper.format_from_activerecord_result(t)
  end
end

def find_company_by_snapshot(snapshot_id)
  Snapshot.where(id: snapshot_id).first.company_id
end
