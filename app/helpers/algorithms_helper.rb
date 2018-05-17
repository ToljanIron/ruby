# frozen_string_literal: true
#############################################################
# - Variables begining with v_ are hash vectors (arrays of hashes) - [{id: 13, score: 0.4}, {id: 8, score: 1.1}, ...]
# - Variables begining with a_ are scalar arrays - [1,2,3,...]
# - Variables begining with s_ are scalares
# - Variables begining with h_ are hashes: {"1": 0.9, "22": 1.1,  ... }
# - When adding a flag algorithm, add similar algorithm for explore; naming convention: <flag_alg_name>_explore
#############################################################

require './app/helpers/cds_util_helper.rb'
require './app/helpers/cds_dfs_helper.rb'
require './app/helpers/cds_selection_helper.rb'
require './app/helpers/cds_employee_management_relation_helper.rb'
include CdsSelectionHelper
include CdsEmployeeManagementRelationHelper

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

  # Email origin/target
  INSIDE_GROUP ||= 1
  OUTSIDE_GROUP ||= 2
  ALL_COMPANY ||= 3

  # From type - init, fwd or reply
  INIT  ||= 1
  REPLY  ||= 2
  FWD  ||= 3

  # Response to meeting
  DECLINE ||= 2

  # Meeting type
  SINGLE ||= 0
  RECCURING ||= 1

  TO ||=1

  BOSS         ||= 10
  ADVICEE_BOSS ||= 11

  Q1 ||= 1
  Q3 ||= 4

  ## Standard deviations
  SD1 ||= 1
  SD2 ||= 2
  SD3 ||= 3

  EPSILON ||= 0.001
  NA ||= -99999

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

  def self.reverse_scores(arr, key)
    ret = arr.dup
    max_entry = ret.max_by{ |e| e[key] }
    max_value = max_entry[key]
    ret.each do |e|
      e[key] = max_value - e[key]
    end
    return ret
  end

  def self.no_of_emails_sent(sid, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.where(id: sid).first.company_id
    emps = get_members_in_group(pid, gid, sid)
    network = NetworkSnapshotData.emails(cid)
    sqlstr = "SELECT from_employee_id, COUNT(DISTINCT(message_id)) AS emails_sum
              FROM network_snapshot_data
              WHERE from_employee_id IN (#{emps.join(',')})
              AND snapshot_id           = #{sid}
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

  def self.no_of_emails_received(sid, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.where(id: sid).first.company_id
    emps = get_members_in_group(pid, gid, sid)
    network = NetworkSnapshotData.emails(cid)
    sqlstr = "SELECT to_employee_id, COUNT(DISTINCT(message_id)) AS emails_sum
              FROM network_snapshot_data
              WHERE to_employee_id IN (#{emps.join(',')})
              AND snapshot_id         = #{sid}
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

  def self.find_limit(sent_emails)
    array_of_values = json_to_array_sinks(sent_emails)
    return array_of_values, 0 if array_of_values.empty?
    q1 = find_q1_max array_of_values
    q3 = find_q3_min array_of_values
    iqr = q3 - q1
    return array_of_values, q3 + iqr * 1.5
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

  def self.do_log(list, hashtable, _strate_infimum)
    new_list = []
    list.each do |li|
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

  def self.avg_subject_length(sid, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, sid)

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


  def self.create_base_line_for_log(emps, candidates)
    return candidates unless is_there_zero(emps, candidates)
    emps.each do |candidate|
      candidates[candidate.to_s] += 1
    end
    return candidates
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

  ###########################################################
  #
  # Calculate bottlenecks by turning the adjacency matrix
  # into a stochastic one (trasition matrix). And looking for
  # the steady state by iteratively multipling it. Once we get
  # a steady state vector, the employees with the highest time
  # proportions are considered bottlenecks.
  #
  ###########################################################
  def calculate_bottlenecks(sid, pid, gid)
    return nil if Group.num_of_emps(gid) < 4

    cid = Snapshot.find(sid).company_id
    nid = NetworkSnapshotData.emails(cid)

    puts "Getting the graph"
    sagraph = get_sagraph(sid, nid, gid)

    a = sagraph[:adjacencymat]
    dim = a.shape[0]
    ones     = get_ones_vector(dim)
    init_vec = NMatrix.new([dim, 1], [(1.0 / dim.to_f)], dtype: :float32)

    puts "Normalizing rows"
    row_degs = a.dot ones
    c = a.snm_map_rows do |r,i|
      row_deg = row_degs[i]
      r.map { |e| e / row_deg }
    end

    puts "Raise to power 64"
    c64 = c.power64

    res = init_vec.transpose.dot c64
    res = res.transpose
    inx2emp = sagraph[:inx2emp]
    ret = []
    res = res.to_a

    puts "extract results"
    (0..res.length-1).each do |i|
      e = res[i]
      ret << {id: inx2emp[i], measure: (100 * e[0]).round(3)}
    end
    return ret
  end

  ################################################################
  # Find observers and return their time in meetings in minutes.
  #   Observers are people whose average email correspondance
  #   with others in their meetings is very low with respect to
  #   company average.
  # For an exact explanation of the calculation see the
  #   algorithms document.
  ################################################################
  def calculate_observers(sid, gid, pid)
    puts "Getting the graph"
    cid = Snapshot.find(sid).company_id
    nid = NetworkSnapshotData.emails(cid)
    sagraph = get_sagraph(sid, nid, gid)

    a = sagraph[:adjacencymat]

    sameetings = get_sameetings(sid, gid)
    m = sameetings[:meetingsmat]

    ## Create total meetings traffix matrix
    mt = a.dot(m) + ((m.transpose).dot(a)).transpose
    ## Now, the same but restricted to the meetings
    ## Remeber that * of an NMatrix is done element by element
    mt = mt * m

    onesvec_meetings = get_ones_vector(a.shape[0]).transpose
    participants_in_meetings = onesvec_meetings.dot(m)
    emails_in_meetings = onesvec_meetings.dot(mt).map { |e| e / 2 }

    ## create an array in which each entry is the number of emails the participants
    ## in the corresponding meeting were involved in (send and recieve) divided
    ## by the number of participants
    emails_density = []
    (0..(emails_in_meetings.shape[1]-1)).each do |i|
      emails_density << emails_in_meetings[0,i] / (participants_in_meetings[0,i])
    end

    stats = DescriptiveStatistics::Stats.new(emails_density)
    avg_emails_per_participant = stats.mean
    sd_emails_per_participant  = stats.standard_deviation

    observer_bound = avg_emails_per_participant - (SD1 * sd_emails_per_participant)

    ## Go over all meetings and collect observer hours
    inx2emp = sagraph[:inx2emp]
    inx2duration = sameetings[:inx2duration]
    ret = []
    i = 0
    mt.each_row do |row|
      time_in_meetings = 0
      row.each_with_index do |emailnum, j|
        emails_density_of_employee  = emailnum / participants_in_meetings[0,j]
        if m[i,j] == 1 && emails_density_of_employee < observer_bound
          time_in_meetings += inx2duration[j]
        end
      end
      ret << {id: inx2emp[i], measure: time_in_meetings}
      i += 1
    end

    return ret
  end

  ################################################################################
  # Recieve array (mtarr) of number of email traffic with meeting participants
  #   and a matrix specifing which employee was in which meeting. Return
  #   a filtered version of mtarr with only entries of employees who participated
  #   in the meeting.
  ################################################################################
  def filter_only_meeting_traffic(mtarr, m)
    filterarr = m.to_flat_a
    ret = []
    mtarr.each_with_index do |v, i|
      ret << v if filterarr[i] == 1
    end
    return ret
  end

  ###########################################################################
  #
  # The connectors algorithm measures how balanced are an employees'
  # destinations. High if he sends to many different groups and low otherwise.
  # The algorithm uses the Blau index which goes like this:
  # 1 - For each employee count how many emails they send to each group their
  #     own (pi)
  # 2 - Divide by total number of emails
  # 3 - Square each ratio
  # 4 - Sum all squares
  # 5 - Subtract from one
  #
  # The formula looks like this:
  #   blau = 1 - sum[ (pi/total)^2 ]
  #
  ###########################################################################
  def calculate_connectors(sid, pid, gid)
    return nil if Group.num_of_emps(gid) < 10

    cid = Snapshot.find(sid).company_id
    nid = NetworkSnapshotData.emails(cid)

    sagraph = get_sagraph(sid, nid, gid)

    a = sagraph[:adjacencymat]
    m = sagraph[:membershipmat]
    inx2emp = sagraph[:inx2emp]

    ## This matrix product produces a new matrix of size employes x groups
    ##   whose entry i,j is how many emails employee i sent towards group j
    am = a.dot m

    empsnum, groupsnum = am.shape
    onesvec_emps = get_ones_vector(empsnum)
    onesvec_grps = get_ones_vector(groupsnum)

    ## Find total numbers of emails sent for each employee
    row_totals = a.dot onesvec_emps

    ## Replace each member of matrix am with the square of the ratio of itself
    ##   and the total number
    c = am.snm_map_rows do |r,i|
      row_tot = row_totals[i]
      r.map { |e| (e.to_f / row_tot.to_f) ** 2 }
    end

    blau_vec = (onesvec_emps - (c.dot onesvec_grps)).transpose

    ret = []
    blau_vec.to_a.each_with_index do |score, i|
      ret << {id: inx2emp[i] , measure: score}
    end
    return ret
  end

  ###########################################################################
  ##
  ## Internal champions
  ## Indegrees whithin the group
  ##
  ###########################################################################
  def internal_champions(sid, pid, gid)
    cid = Snapshot.find(sid).company_id
    nid = NetworkSnapshotData.emails(cid)
    empids = get_members_in_group(pid, gid, sid).sort
    return [] if empids.count == 0
    empsstr = empids.join(',')

    sqlstr =
      "SELECT to_employee_id, count(*) AS indeg FROM network_snapshot_data
      WHERE
        snapshot_id = #{sid} AND
        company_id = #{cid} AND
        network_id = #{nid} AND
        to_employee_id IN (#{empsstr}) AND
        from_employee_id IN (#{empsstr})
      GROUP By to_employee_id
      ORDER BY indeg"
    res = ActiveRecord::Base.connection.select_all(sqlstr)
    ret = []
    res.each do |e|
      ret << {id: e['to_employee_id'], measure: e['indeg'].to_f}
    end
    return ret
  end

  def avg_number_of_recipients(sid, pid, gid)
    cid = Snapshot.find(sid).company_id
    nid = NetworkSnapshotData.emails(cid)
    sqlstr =
       "SELECT cnt FROM
         (SELECT message_id, COUNT(*) AS cnt
          FROM network_snapshot_data AS nsd
          WHERE
            snapshot_id = #{sid} AND
            network_id = #{nid}
          GROUP BY message_id) AS in1"
     res = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

     res = res.map { |r| r['cnt'] }
     med = array_mean(res)
     return [{group_id: gid, measure: med}]
  end


  ###########################################################################
  ## Group non-reciprocity
  ## This algorithm expects to find resutls for external_receive and for
  ## external_send.
  ###########################################################################
  def group_non_reciprocity(sid, gid)
    rec = CdsMetricScore
      .where(snapshot_id: sid)
      .where(group_id: gid)
      .where(algorithm_id: 300)
      .last

    snd = CdsMetricScore
      .where(snapshot_id: sid)
      .where(group_id: gid)
      .where(algorithm_id: 301)
      .last

    if rec.nil? || snd.nil?
      puts "Could not calculate non-reciprocity for group: #{gid}, because pre-requises are not present"
      return [{id: gid, measure: NA}]
    end

    rec = rec[:score].to_f
    snd = snd[:score].to_f

    if (snd == 0 && rec == 0)
      return [{id: gid, measure: NA}]
    end

    score = 1 - (rec.to_f / (snd.to_f + rec.to_f + EPSILON) ).round(2)
    return [{id: gid, measure: score}]
  end

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
  def self.employees_network_non_reciprocity_scores(sid, pid, gid)
    cid = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, sid).sort
    return [] if emps.count == 0
    empsstr = emps.join(',')
    nid = NetworkSnapshotData.emails(cid)

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
  ## The score between each pair of employees is between 1 and -1, where:
  ##   0 - email traffic is same in both directions
  ##   1 - Only sending
  ##  -1 - Only receiving
  ##
  ## 1 - select rows like:
  ##   {"from_employee_id"=>"1", "to_employee_id"=>"2", "outsum"=>"2", "diff"=>"0"}
  ##   where outsum are emp 1 outdegrees and diff is the difference between his
  ##   outdgree to emp 2 and the indgree from emp2
  ## 2 - for each entry calculate the ratio between indegree and outdgree
  ## 3 - Sum for every employee, and return the average
  ############################################################################
  def self.employees_email_non_reciprocity_scores(sid, pid, gid)
    cid = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, sid).sort
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
    number_of_emails = {}
    outdegrees.each do |indeg|
      ratio = -1

      ## The join from above return a nil in diff value if to_emp did not return email traffic to from_emp
      ## It will return a negative number if the email traffix was less
      ## and positive diff otherwise.
      ratio = if indeg['diff'].nil?
                outdegrees_hash[indeg['to_employee_id']] = -1
                number_of_emails[indeg['to_employee_id']] = number_of_emails[indeg['to_employee_id']].nil? ? 0 : number_of_emails[indeg['to_employee_id']] + 1
                1
              else
                (indeg['diff'].to_f / indeg['outsum'].to_f).round(2)
              end

      if outdegrees_hash[indeg['from_employee_id']].nil?
        outdegrees_hash[indeg['from_employee_id']] = ratio
        number_of_emails[indeg['from_employee_id']] = 1
      else
        outdegrees_hash[indeg['from_employee_id']] += ratio
        number_of_emails[indeg['from_employee_id']] += 1
      end
    end

    outdegrees_unique_hash = {}
    outdegrees_hash.each do |e|
      outdegrees_unique_hash[e[0].to_s] = e[1].to_f / number_of_emails[e[0]]
    end

    return outdegrees_unique_hash
  end

  def self.calculate_non_reciprocity_between_employees(sid, pid = NO_PIN, gid = NO_GROUP)
    res = employees_email_non_reciprocity_scores(sid, pid, gid)
    ret = []
    res.each do |k, v|
      ret << { id: k.to_i, measure: v }
    end
    return ret
  end

  def self.find_empty_networks(sid, nid_1, nid_2, emps)
    NetworkSnapshotData.where(snapshot_id: sid, network_id: nid_1, to_employee_id: emps, from_employee_id: emps).empty? && NetworkSnapshotData.where(snapshot_id: sid, network_id: nid_2, to_employee_id: emps, from_employee_id: emps).empty?
  end

  def self.find_empty_network_and_email(sid, nid_1, emps)
    NetworkSnapshotData.where(snapshot_id: sid, network_id: nid_1, to_employee_id: emps, from_employee_id: emps).empty?
  end

  def self.volume_json_to_array(v_email_degs)
    arra = []
    v_email_degs.each do |email_deg|
      arra.push(email_deg[:measure])
    end
    return arra
  end

  def self.volume_of_emails(sid, pid = NO_PIN, gid = NO_GROUP)
    company = Snapshot.find(sid).company_id
    v_email_degs = volume_for_group(sid, company, pid, gid)
    v_email_degs = grade_all_groups(company, sid, v_email_degs)
    v_email_degs = sort_results(v_email_degs)
    return v_email_degs
  end

  def self.volume_of_emails_for_explore(sid, pid = NO_PIN, gid = NO_GROUP)
    emp_arr = get_members_in_group(pid, gid, sid)
    arr = []
    emp_arr.each do |emp_one|
      arr.push(id: emp_one, measure: 0)
    end
    return arr
  end

  def self.no_of_isolates(sid, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.find(sid).company_id
    emps = get_members_in_group(pid, gid, sid)
    network = NetworkSnapshotData.emails(cid)
    sqlstr = "SELECT COUNT(id) AS emails_sum
              FROM network_snapshot_data
              WHERE network_id      = #{network}
              AND snapshot_id       = #{sid}
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
              AND snapshot_id       = #{sid}
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

  def self.no_of_isolates_for_explore(sid, pid = NO_PIN, gid = NO_GROUP)
    emp_arr = get_members_in_group(pid, gid, sid)
    arr = []
    emp_arr.each do |emp_one|
      arr.push(id: emp_one, measure: 0)
    end
    return arr
  end

  def self.grade_all_groups(cid, sid, v_email_degs)
    group_degrees = []
    Group.by_snapshot(sid).where(company_id: cid).each do |grp|
      emp_arr = get_members_in_group(NO_PIN, grp.id, sid)
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

  def self.get_measure_for_employee(v_email_degs, id)
    result = 0
    v_email_degs.each do |deg|
      result = deg[:measure] if deg[:id] == id
    end
    result
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

  def self.id_exists_in_results(array, item)
    found = false
    array.each do |it|
      found = true if it[:id] == item.to_i
    end
    return found
  end

  def self.find_min(arr)
    min = 0
    min = arr[0][:measure] unless arr.empty?
    arr.each do |obj|
      min = obj[:measure] if obj[:measure].to_i <= min
    end
    return min
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

  def self.exists_in_metrics(all_metrix, emp_id)
    res = false
    all_metrix.each do |metric|
      res = true if metric[:id].to_i == emp_id.to_i
    end
    return res
  end

  def self.calculate_inn_degree_email(sid, _network_id, cid, pid = NO_PIN, gid = NO_GROUP)
    all_metrix = calc_indegree_for_all_matrix_in_relation_to_company(sid, gid, pid)
    emps = get_members_in_group(pid, gid, sid)
    emps.each do |emp_id|
      all_metrix.push(id: emp_id.to_i, measure: 0) unless exists_in_metrics(all_metrix, emp_id)
    end
    return all_metrix
  end

  def self.remove_managers(employees_with_grades, sid)
    result = []
    employees_with_grades.each do |emp|
      result.push(emp) if no_manager?(emp[:id].to_i, sid)
    end
    result
  end

  def self.no_manager?(id, sid)
    return EmployeeManagementRelation
             .joins("JOIN employees as emps ON emps.id = employee_management_relations.employee_id")
             .where(manager_id: id)
             .where("emps.snapshot_id = #{sid}")
             .empty?
  end

  def calculate_powerful_non_managers(sid, pid = NO_PIN, gid = NO_GROUP)
    cid = Snapshot.find(sid).company_id
    puts "cid: #{cid}, sid: #{sid}, gid: #{gid}"
    all_metrix_and_employees = calculate_inn_degree_email(sid, nil, cid, pid, gid)
    emps_without_managers = remove_managers(all_metrix_and_employees, sid)
    emps_without_managers = emps_without_managers.sort! {|a,b| b[:measure] <=> a[:measure]}
    return emps_without_managers
  end

  def self.calculate_pair_for_specific_relation_per_snapshot(sid, network_id, pid = NO_PIN, gid = NO_GROUP)
    inner_select = AlgorithmsHelper.get_inner_select(pid, gid)
    snapshot = Snapshot.find(sid)
    dt = snapshot.timestamp.to_i
    query = AlgorithmsHelper.get_relation_arr(pid, gid, sid, network_id)
    unless inner_select.blank?
      query += " and from_employee_id in (#{inner_select} ) " \
      "and to_employee_id in (#{inner_select}) "
    end
    temp_res = ActiveRecord::Base.connection.select_all(query)
    return AlgorithmsHelper.format_to_analyze_algorithm(temp_res, dt)
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

  ## Sum of indegrees and outdegrees of all employees
  def most_isolated_workers(sid, gid = NO_GROUP)
    emails_network = NetworkName.get_emails_network(Snapshot.find(sid).company_id)
    emps_arr = Group.find(gid).extract_employees
    emps_str = emps_arr.join(',')
    ret = []
    return ret if emps_arr.length < 10

    sqlstr = "
      SELECT empid, SUM(tempsums.empscore) AS totalscore FROM
        (SELECT femp.id AS empid, SUM(fnsd.value) AS empscore
        FROM network_snapshot_data AS fnsd
        JOIN employees AS femp on femp.id = fnsd.from_employee_id
        WHERE
        fnsd.snapshot_id = #{sid}  AND
        fnsd.network_id = #{emails_network} AND
        femp.id IN (#{emps_str})
        GROUP BY femp.id
        UNION
        SELECT temp.id AS empid, SUM(tnsd.value) AS empscore
        FROM network_snapshot_data AS tnsd
        JOIN employees AS temp ON temp.id = tnsd.to_employee_id
        WHERE
        tnsd.company_id = #{sid} AND
        tnsd.network_id = #{emails_network} AND
        temp.id IN (#{emps_str})
        GROUP BY temp.id) AS tempsums
      GROUP BY empid
      ORDER BY totalscore ASC"

    res = ActiveRecord::Base.connection.select_all(sqlstr)
    res.each do |e|
      eid = e['empid']
      emps_arr.delete(eid)
      ret << {id: eid, measure: e['totalscore'].to_i}
    end

    # Padding for employees having no connections
    zeroscores = []
    emps_arr.each do |emp|
      zeroscores << {id: emp, measure: 0}
    end
    ret = zeroscores + ret
    ret = AlgorithmsHelper.reverse_scores(ret, :measure)
    return zeroscores + ret
  end

  def get_friends_relation_in_network(sid, nid, pid = NO_PIN, gid = NO_GROUP, in_or_out = 'in') ## need to convert
    cid = AlgorithmsHelper.get_company_id(sid)
    f = if in_or_out == 'in'
          get_list_of_employees_in(sid, nid, pid, gid)
        else
          get_list_of_employees_out(sid, nid, pid, gid)
        end
    unit_size = CdsGroupsHelper.get_unit_size(cid, pid, gid)
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

  ###############################################################################
  # Assign each manager a bypassed score. If an employee is not a manager  then
  # they do not get a score at all.
  # There are 4 types of players in this calculation:
  # i - The employees
  # j - The manager
  # k - The manager's manager
  # m - The manager's peers
  #
  # We designate Traffic from one group to another, for example from employees
  #   to the manager by: Aij.
  #
  # The overall score is 1 minus the average of the following qoutients:
  # 1. a1 = Aik / (Aij + Aik)
  # 2. a2 = Aki / (Akj + Aki)
  # 3. a3 = Aim / (Aij + Aim)
  # 4. a4 = Ami / (Amj + Ami)
  #
  # So, the lower the score the more bypassed is the manager k.
  #
  ###############################################################################
  def most_bypassed_managers(cid, sid, pid = NO_PIN, gid = NO_GROUP)
    nid = NetworkName.get_emails_network(cid)
    sag = get_sagraph(sid, nid, gid)
    fsi = formal_structure_index(sid)
    mids = fsi[:managers].clone.values.uniq
    mids.delete( fsi[:topid] )

    a        = sag[:adjacencymat]
    emp2inx  = sag[:emp2inx]
    emps_num = a.shape[0]

    ret = []

    mids.each do |mid|
      j = emp2inx[mid]
      mmid = fsi[:managers][mid]
      next if mmid.nil?
      k = emp2inx[mmid]

      ## Get vectors of: Managers' peers and reportees
      vp, vr = get_identification_vecotrs(emps_num, fsi, mid, emp2inx)

      ## Employees to manager and top manager
      aik = vr.transpose.dot( a.col(k) )[0]
      aij = vr.transpose.dot( a.col(j) )[0]
      a1 = (aik / (aik + aij + EPSILON)).round(3)

      ## Top manager to employees and manager
      aki = a.row(k).dot(vr)[0]
      akj = a[k,j]
      a2 = (aki / (aki + akj + EPSILON)).round(3)

      ## Employees to peers and manager
      aim = vr.transpose.dot( a.dot(vp) )[0,0]
      a3 = (aim / (aim + aij + EPSILON)).round(3)

      ## Peers to manager and employees
      ami = vp.transpose.dot( a.dot(vr) )[0,0]
      amj = vp.transpose.dot( a.col(j) )[0]
      a4 = (ami / (amj + ami + EPSILON)).round(3)

      measure = 1 - (0.25 * (a1 + a2 + a3 + a4)).round(2)
      ret << {id: mid, measure: measure}
    end
    return ret
  end

  def get_identification_vecotrs(emps_num, fsi, mid, emp2inx)
    zeros =  NMatrix.zeros([emps_num, 1], dtype: :float32)

    vp  = zeros.clone
    fsi[:peers][mid].each { |peerid| vp[emp2inx[peerid]] = 1 }

    vr  = zeros.clone
    fsi[:reportees][mid].each { |eid| vr[emp2inx[eid]] = 1 }

    return [vp, vr]
  end

  ################################################## Gauges #############################################

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
  def self.density_of_network(sid, gid, pid, nid)
    cid = find_company_by_snapshot(sid)

    n = get_all_emps(cid, pid, gid).count
    group_id = (gid == -1 ? pid : gid)
    return [{ group_id: group_id, measure: 0.0 }] if n <= 3

    s_max_email_traffic   = s_calc_max_traffic_between_two_employees(sid, nid, gid, pid)
    s_sum_traffic_network = s_calc_sum_of_matrix(sid, gid, pid, nid)

    if(s_max_email_traffic.nil?)
      network_density = 0
    else
      network_density = (s_sum_traffic_network.to_f / (n * s_max_email_traffic)).round(3)
    end

    return [{ group_id: group_id, measure: network_density }]
  end

  def self.network_traffic_standard_err(sid, gid, pid, nid)
    group_id = (gid == -1 ? pid : gid)

    traffic = calc_emails_volume(sid, gid, pid)

    arr = traffic.map {|t| t[:measure]}

    if(arr.count === 1)
      strd_err = 0
    else
      strd_err = array_sd(arr)
    end

    return [{ group_id: group_id, measure: strd_err }]
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
      emps = get_members_in_group(pid, gid, sid)
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

  ##################### V3 algorithms ###################################################

  ##################### Emails #####################

  def spammers_measure(sid, gid, pid)
    return calc_outdegree_for_to_matrix(sid, INSIDE_GROUP, gid, pid)
  end

  def blitzed_measure(sid, gid, pid)
    return calc_indegree_for_to_matrix(sid, INSIDE_GROUP, gid, pid)
  end

  def ccers_measure(sid, gid, pid)
    return calc_ccers(sid, gid, pid)
  end

  def cced_measure(sid, gid, pid)
    return calc_cced(sid, gid, pid)
  end

  def undercover_measure(sid, gid, pid)
    return calc_undercover(sid, gid, pid)
  end

  def politicos_measure(sid, gid, pid)
    return calc_politicos(sid, gid, pid)
  end

  def emails_volume_measure(sid, gid, pid)
    return calc_emails_volume(sid, gid, pid)
  end

  def deadends_measure(sid, gid, pid)
    return calc_deadends(sid, gid, pid)
  end

  def closeness_of_email_network(sid, gid, pid)
    nid = NetworkName.get_emails_network(Snapshot.find(sid).company_id)
    return density_of_network(sid, gid, pid, nid)
  end

  def synergy_of_email_network(sid, gid, pid)
    nid = NetworkName.get_emails_network(Snapshot.find(sid).company_id)
    return network_traffic_standard_err(sid, gid, pid, nid)
  end

  ###################################################

  ##################### Meetings #####################

  def in_the_loop_measure(sid, gid, pid)
    return calc_in_the_loop(sid, gid, pid)
  end

  def rejecters_measure(sid, gid, pid)
    return calc_rejecters(sid, gid, pid)
  end

  def routiners_measure(sid, gid, pid)
    return calc_routiners(sid, gid, pid)
  end

  def inviters_measure(sid, gid, pid)
    return calc_inviters(sid, gid, pid)
  end

  def avg_num_of_ppl_in_meetings(sid, gid, pid)
    return calc_avg_num_of_ppl_in_meetings(sid, gid, pid)
  end

  ###################################################

  ##################### V3 formatting utilities ###################################################
  def result_zero_padding(empids, scores)
    res = []
    empids.each do |eid|
      score = scores.find { |s| s[:id] == eid.to_i || s[:id] == eid.to_s }
      res << score if !score.nil?
      res << {id: eid, measure: 0} if score.nil?
    end
    return res
  end

  ###################### Email utilities #################################################

  def calc_indegree_for_all_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_all_matrix(snapshot_id, EMAILS_IN, INSIDE_GROUP, group_id, pin_id)
  end

  def calc_indegree_for_all_matrix_in_relation_to_company(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_all_matrix(snapshot_id, EMAILS_IN, INSIDE_GROUP, group_id, pin_id)
  end

  def calc_outdegree_for_all_matrix_in_relation_to_company(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_all_matrix(snapshot_id, EMAILS_OUT, INSIDE_GROUP, group_id, pin_id)
  end

  def calc_outdegree_for_all_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_all_matrix(snapshot_id, EMAILS_OUT, INSIDE_GROUP, group_id, pin_id)
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

  def calc_indegree_for_to_matrix(snapshot_id, target_groups, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_specified_matrix(snapshot_id, TO_MATRIX, EMAILS_IN, target_groups, group_id, pin_id)
  end

  def calc_indegree_for_cc_matrix(snapshot_id, target_groups, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_specified_matrix(snapshot_id, CC_MATRIX, EMAILS_IN, target_groups, group_id, pin_id)
  end

  def calc_indegree_for_bcc_matrix(snapshot_id, target_groups, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_specified_matrix(snapshot_id, BCC_MATRIX, EMAILS_IN, target_groups, group_id, pin_id)
  end

  def calc_outdegree_for_to_matrix(snapshot_id, target_groups, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_outdeg_for_specified_matrix(snapshot_id, TO_MATRIX, target_groups, group_id, pin_id)
  end

  def calc_outdegree_for_cc_matrix(snapshot_id, target_groups, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_outdeg_for_specified_matrix(snapshot_id, CC_MATRIX, target_groups, group_id, pin_id)
  end

  def calc_outdegree_for_bcc_matrix(snapshot_id, target_groups, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_outdeg_for_specified_matrix(snapshot_id, BCC_MATRIX, target_groups, group_id, pin_id)
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

  def self.s_calc_max_traffic_between_two_employees(sid, nid, gid = NO_GROUP, pid = NO_PIN)
    res = h_calc_max_traffic_between_two_employees_with_ids(sid, nid, gid, pid)
    return nil if res.nil? || res.empty?
    return res[:max].to_i
  end

  def self.h_calc_max_traffic_between_two_employees_with_ids(sid, nid, gid = NO_GROUP, pid = NO_PIN)
    emps = get_members_in_group(pid, gid, sid).sort
    return [] if emps.count == 0
    empsstr = emps.join(',')
    # network = NetworkSnapshotData.emails(cid)
    network = nid
    sqlstr = "SELECT outter_nsd.from_employee_id, outter_nsd.to_employee_id, COUNT(id) AS maximum_traffic
              FROM network_snapshot_data AS outter_nsd
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

  def self.s_calc_sum_of_matrix(sid, gid = NO_GROUP, pid = NO_PIN, nid = NO_NETWORK)
    emps = get_members_in_group(pid, gid, sid).sort
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

  #############################################################################
  # Create a set of structures for handling the email traffic adjaceny matrix.
  #   The main data structure is adjacencymat which is a matrix used for fast
  #   calculations (The gem in use here is: nmatrix). Also there are two mappings
  #   between matrix indexes and real employee IDs.
  #   The second structure in use here is a matrix mapping employees to groups,
  #   again, with two accompanying indexes for the groups.
  ############################################################################
  def get_sagraph(sid, nid, gid)
    key = "sagraph-sid-#{sid}-nid-#{nid}-gid-#{gid}"
    CdsUtilHelper.read_or_calculate_and_write(key) do
      return get_sagraph_block(sid, nid, gid)
    end
  end

  def get_sagraph_block(sid, nid, gid)
    eids = Group.find(gid).extract_employees.sort
    gids = Group.get_all_subgroups(gid)

    emps_structures = get_sagraph_block_from_eids(sid, nid, eids)
    emp2inx = emps_structures[:emp2inx]
    inx2emp = emps_structures[:inx2emp]
    adjacencymat = emps_structures[:adjacencymat]

    ## group indexes
    inx2grp = {}
    grp2inx = {}
    gids.each do |id|
      grp2inx[id] = inx2grp.size
      inx2grp[inx2grp.size] = id
    end

    ## Popoulate group membership matrix
    memmat = get_sa_membership_matrix(emp2inx, grp2inx, gids)

    return {
      emp2inx: emp2inx,
      inx2emp: inx2emp,
      adjacencymat: adjacencymat,
      grp2inx: grp2inx,
      inx2grp: inx2grp,
      membershipmat: memmat
    }
  end

  def get_sagraph_block_from_eids(sid, nid, eids)
    dim = eids.length

    edges = NetworkSnapshotData
      .select(:from_employee_id, :to_employee_id)
      .where(snapshot_id: sid, network_id: nid)
      .where(from_employee_id: eids, to_employee_id: eids)

    ## Create the employee indexes
    inx2emp, emp2inx = create_employee_indexes(eids)

    ## Populate adjacency matrix
    allarr = Array.new(dim ** 2, 0)
    edges.each do |edge|
      from = emp2inx[edge[:from_employee_id]]
      to   = emp2inx[edge[:to_employee_id]]
      index = dim * from + to
      allarr[index] += 1
    end
    adjacencymat = NMatrix.new([dim, dim], allarr, dtype: :float32)
    adjacencymat = set_one_on_diagonal_of_empty_rows(adjacencymat)
    return {
      emp2inx: emp2inx,
      inx2emp: inx2emp,
      adjacencymat: adjacencymat
    }
  end

  def create_employee_indexes(eidsarr)
    inx2emp = {}
    emp2inx = {}
    eidsarr.each do |id|
      emp2inx[id] = inx2emp.size
      inx2emp[inx2emp.size] = id
    end
    return [inx2emp, emp2inx]
  end

  ##################################################################
  # Create a matrix mapping employees to groups. ie, employee in row
  #   i belongs to group in column j if Mij = 1.
  ##################################################################
  def get_sa_membership_matrix(emp2inx, grp2inx, gids)
    sid = Group.find(gids.first).snapshot_id
    groupemps = Employee
      .select(:id, :group_id)
      .where(snapshot_id: sid, group_id: gids)

    memmat = NMatrix.new([emp2inx.length, grp2inx.length], 0, dtype: :int64)
    groupemps.each do |emp|
      row = emp2inx[emp[:id]]
      col = grp2inx[emp[:group_id]]
      memmat[row, col] = 1
    end
    return memmat
  end


  ##################################################################
  # If there are p employees and m meetings, then create a b by m
  #   boolean matrix which maps employees to meetings. Also create
  #   indexes between meeting IDs and matrix columns.
  ##################################################################
  def get_sameetings(sid, gid)
    key = "sameetings-sid-#{sid}-gid-#{gid}"
    CdsUtilHelper.read_or_calculate_and_write(key) do
      return get_sameetings_block(sid, gid)
    end
  end

  def get_sameetings_block(sid, gid)
    eids = Group.find(gid).extract_employees.sort

    meeting_emps_pairs = MeetingsSnapshotData
      .select('msd.id AS mid, ma.employee_id AS eid')
      .from('meetings_snapshot_data AS msd')
      .joins('JOIN meeting_attendees AS ma ON ma.meeting_id = msd.id')
      .where('msd.snapshot_id = ?', sid)
      .where("ma.employee_id in (#{eids.join(',')})", eids)
      .order('mid, eid')

    meetings = MeetingsSnapshotData
      .select('DISTINCT msd.id, msd.duration_in_minutes AS duration')
      .from('meetings_snapshot_data AS msd')
      .joins('JOIN meeting_attendees AS ma ON ma.meeting_id = msd.id')
      .where('msd.snapshot_id = ?', sid)
      .where("ma.employee_id in (#{eids.join(',')})", eids)
      .order('msd.id')

    ## Create the meetings indexes
    inx2meeting = {}
    meeting2inx = {}
    inx2duration = {}
    meetings.each do |m|
      meeting2inx[m[:id]] = inx2meeting.size
      inx2duration[inx2meeting.size] = m[:duration]
      inx2meeting[inx2meeting.size] = m[:id]
    end

    empsdim = eids.length
    meetingsdim = meetings.size

    ## Populate meetings matrix
    allarr = Array.new(empsdim * meetingsdim, 0)
    emp2inx = create_employee_indexes(eids)[1]
    meeting_emps_pairs.each do |pair|
      emp  = emp2inx[pair[:eid]]
      meet = meeting2inx[pair[:mid]]
      index = meetingsdim * emp + meet
      allarr[index] += 1
    end
    meetingsmat = NMatrix.new([empsdim, meetingsdim], allarr, dtype: :int64)

    return {
      meeting2inx: meeting2inx,
      inx2meeting: inx2meeting,
      meetingsmat: meetingsmat,
      inx2duration: inx2duration
    }
  end

  def set_one_on_diagonal_of_empty_rows(nm)
    return nm.snm_map_rows do |r, i|
      ret = nil
      if r.sum > 0
        ret = r
      else
        dim = r.length
        ret = Array.new(dim, 0)
        ret[i] = 1
      end
      ret
    end
  end

  def get_ones_vector(dim)
    return NMatrix.ones([dim, 1], dtype: :float32)
  end

  def get_ones_nmatrix(dim)
    return NMatrix.ones([dim, dim], dtype: :float32)
  end

  ######################################################################################

  def calc_degree_for_all_matrix(snapshot_id, direction, target_groups, group_id = NO_GROUP, pin_id = NO_PIN)
    if direction == EMAILS_IN
      to_degree  = calc_indegree_for_to_matrix(snapshot_id, target_groups, group_id, pin_id)
      cc_degree  = calc_indegree_for_cc_matrix(snapshot_id, target_groups, group_id, pin_id)
      bcc_degree = calc_indegree_for_bcc_matrix(snapshot_id, target_groups, group_id, pin_id)
    else
      to_degree  = calc_outdegree_for_to_matrix(snapshot_id, target_groups, group_id, pin_id)
      cc_degree  = calc_outdegree_for_cc_matrix(snapshot_id, target_groups, group_id, pin_id)
      bcc_degree = calc_outdegree_for_bcc_matrix(snapshot_id, target_groups, group_id, pin_id)
    end
    union = to_degree + cc_degree + bcc_degree

    return sum_and_minimize_array_of_hashes_by_key(union, 'id', 'measure')
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

  def calc_degree_for_specified_matrix(sid, matrix_name, direction, target_groups, gid = NO_GROUP, pid = NO_PIN)
    cid = find_company_by_snapshot(sid)
    nid = NetworkSnapshotData.emails(cid)
    res = []
    inner_select = get_inner_select_as_arr(cid, pid, gid)

    where_part = get_where_part_for_specified_matrix(direction, target_groups, inner_select)

    current_snapshot_nodes = NetworkSnapshotData.where(snapshot_id: sid, network_id: nid)

    if matrix_name === BCC_MATRIX
      current_snapshot_nodes = current_snapshot_nodes.where(to_type: matrix_name)
        .where(where_part).where("to_employee_id != from_employee_id").select("#{direction} as id, count(id) as total_sum").group(direction).order(direction)
    else
      current_snapshot_nodes = current_snapshot_nodes.where(to_type: matrix_name)
      .where(where_part).select("#{direction} as id, count(id) as total_sum").group(direction).order(direction)
    end

    current_snapshot_nodes.each do |emp|
      res << { id: emp.id, measure: emp.total_sum }
    end
    return result_zero_padding(inner_select, res)
  end

  def get_where_part_for_specified_matrix(direction, target_groups, inner_select)
    # Default is only inside group
    where_part = "from_employee_id IN (#{inner_select.join(',')}) AND to_employee_id IN (#{inner_select.join(',')})"
    if(direction === EMAILS_OUT)
      if(target_groups === OUTSIDE_GROUP)
        where_part = "from_employee_id IN (#{inner_select.join(',')}) AND to_employee_id NOT IN (#{inner_select.join(',')})"
      elsif(target_groups === ALL_COMPANY)
        where_part = "from_employee_id IN (#{inner_select.join(',')})"
      end
    else
      if(target_groups === OUTSIDE_GROUP)
        where_part = "to_employee_id IN (#{inner_select.join(',')}) AND from_employee_id NOT IN (#{inner_select.join(',')})"
      elsif(target_groups === ALL_COMPANY)
        where_part = "to_employee_id IN (#{inner_select.join(',')})"
      end
    end
    return where_part
  end

  ############################ ALL MATRIX IMPLEMENTATION #########################################

  def calc_indeg_for_specified_matrix_relation_to_company(snapshot_id, matrix_name, group_id = NO_GROUP, pin_id = NO_PIN)
    return calc_degree_for_specified_matrix_with_relation_to_company(snapshot_id, matrix_name, EMAILS_IN, group_id, pin_id)
  end

  def calc_outdeg_for_specified_matrix(snapshot_id, matrix_name, target_groups, group_id = NO_GROUP, pin_id = NO_PIN)
    return calc_degree_for_specified_matrix(snapshot_id, matrix_name, EMAILS_OUT, target_groups, group_id, pin_id)
  end

  def calc_outdeg_for_specified_matrix_relation_to_company(snapshot_id, matrix_name, group_id = NO_GROUP, pin_id = NO_PIN)
    return calc_degree_for_specified_matrix_with_relation_to_company(snapshot_id, matrix_name, EMAILS_OUT, group_id, pin_id)
  end

  def calc_normalized_degree_for_specified_matrix(snapshot_id, matrix_name, direction, group_id = NO_GROUP, pin_id = NO_PIN)
    res = calc_degree_for_specified_matrix(snapshot_id, matrix_name, direction, INSIDE_GROUP, group_id, pin_id)
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
      result_vector = calc_outdeg_for_specified_matrix(snapshot_id, matrix_name, INSIDE_GROUP, -1, -1)
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
    result_vector = calc_outdeg_for_specified_matrix(snapshot_id, matrix_name, INSIDE_GROUP, -1, -1)
    calc_max_vector(result_vector)
  end

  def calc_max_vector(emp_vector)
    return calc_max_in_vector_by_attribute(emp_vector, :measure)
  end

  def calc_max_in_vector_by_attribute(emp_vector, attribute)
    return emp_vector.map { |elem| elem[attribute.to_s.to_sym] }.max
  end

  ################  ###########################################

  def calc_ccers(sid, gid = NO_GROUP, pid = NO_PIN)
    cid = find_company_by_snapshot(sid)
    inner_select = get_inner_select_as_arr(cid, pid, gid)
    total_cc_outdegree = calc_outdegree_for_cc_matrix(sid, INSIDE_GROUP, gid, pid)
    res = format_activerecord_relation_to_algorithm_result(total_cc_outdegree)
    return result_zero_padding(inner_select, res)
  end

  def calc_cced(sid, gid = NO_GROUP, pid = NO_PIN)
    cid = find_company_by_snapshot(sid)
    inner_select = get_inner_select_as_arr(cid, pid, gid)
    total_cc_indegree = calc_indegree_for_cc_matrix(sid, INSIDE_GROUP, gid, pid)
    res = format_activerecord_relation_to_algorithm_result(total_cc_indegree)
    return result_zero_padding(inner_select, res)
  end

  def calc_undercover(sid, gid = NO_GROUP, pid = NO_PIN)
    cid = find_company_by_snapshot(sid)
    inner_select = get_inner_select_as_arr(cid, pid, gid)
    total_bcc_outdegree = calc_outdegree_for_bcc_matrix(sid, INSIDE_GROUP, gid, pid)
    res = format_activerecord_relation_to_algorithm_result(total_bcc_outdegree)
    return result_zero_padding(inner_select, res)
  end

  def calc_politicos(sid, gid = NO_GROUP, pid = NO_PIN)
    cid = find_company_by_snapshot(sid)
    inner_select = get_inner_select_as_arr(cid, pid, gid)
    total_bcc_indegree = calc_indegree_for_bcc_matrix(sid, INSIDE_GROUP, gid, pid)
    res = format_activerecord_relation_to_algorithm_result(total_bcc_indegree)
    return result_zero_padding(inner_select, res)
  end

  def relays_measure(sid, gid = NO_GROUP, pid = NO_PIN)
    res = []
    cid = find_company_by_snapshot(sid)
    nid = NetworkSnapshotData.emails(cid)
    emps = Employee.where(snapshot_id: sid).pluck(:id)

    fwded_emails =
      NetworkSnapshotData.where(snapshot_id: sid,
                                network_id: nid,
                                from_type: FWD,
                                to_type: TO)
                         .select("#{EMAILS_OUT} as id, count(id) as measure")
                         .group(EMAILS_OUT)

    res = format_activerecord_relation_to_algorithm_result(fwded_emails)
    ret = result_zero_padding(emps, res)
    return ret
  end

  def format_activerecord_relation_to_algorithm_result(active_record_rel)
    return active_record_rel if active_record_rel.nil?
    return active_record_rel if active_record_rel.class == Array
    res = []
    active_record_rel.each do |a|
      res << {id: a.id, measure: a.measure}
    end
    return res
  end

  def calc_emails_volume(sid, gid = NO_GROUP, pid = NO_PIN)
    res = []
    in_result = calc_degree_for_all_matrix(sid, EMAILS_IN, INSIDE_GROUP, gid, pid)
    out_result = calc_degree_for_all_matrix(sid, EMAILS_OUT, INSIDE_GROUP, gid, pid)
    union = in_result + out_result

    temp = sum_and_minimize_array_of_hashes_by_key(union, 'id', 'measure')

    res = symbolize_hash_arr(temp)
    return res
  end

  def calc_deadends(sid, gid = NO_GROUP, pid = NO_PIN)

    res = []
    cid = find_company_by_snapshot(sid)
    nid = NetworkSnapshotData.emails(cid)
    emps = get_inner_select_as_arr(cid, pid, gid)
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
              snapshot_id = #{sid} AND
              from_type = #{REPLY}
              GROUP BY fromnsd.from_employee_id) AS fromemps ON fromemps.fromempid = emps.id
        WHERE emps.id in (#{emps.join(',')}) AND
              emps.snapshot_id = #{sid}
        ORDER BY emps.id"
    sqlres = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

    ratios = []

    missing_to_and_from = -1 # Illegal entry
    missing_from = -2 # Should be same as max entry

    sqlres.each do |e|
      toempcount   = e['toempcount']
      fromempcount = e['fromempcount']

      elm = {}
      elm[:id] = e['empid']

      if fromempcount.nil?
        if toempcount.nil?
          elm[:measure] = missing_to_and_from
        else
          elm[:measure] = missing_from
        end
      end
      elm[:measure] = toempcount.to_f / fromempcount.to_f if (!toempcount.nil? && !fromempcount.nil?)

      ratios << elm
    end

    # Find max measure for sink/deadend. Then, use it to populate employees with
    # missing reply - because we can't divide be zero, and we can't guess the max
    # measure in advance. Employees with no reply are automatically at the max
    # sink/deadend measure - because they never reply.

    max_deadend_measure = 0
    ratios.each do |r|
      m = r[:measure]
      next if m.nil?
      max_deadend_measure = r[:measure] if m > max_deadend_measure
    end

    # In the case that there is no reply and no max measure - set all max to some
    # arbitrary high value
    # max_deadend_measure = 111 if max_deadend_measure == 0

    ratios.each do |r|
      r[:measure] = max_deadend_measure if r[:measure] == missing_from
      r[:measure] = 0 if r[:measure].nil?
    end

    ratios = ratios.sort { |a,b| a[:measure] <=> b[:measure] }

    ratios.each do |r|
      res << { id: r[:id].to_i, measure: r[:measure].to_i }
    end
    return res
  end

  def external_receivers_volume(sid, gid = NO_GROUP, pid = NO_PIN)
    cid = find_company_by_snapshot(sid)
    nid = NetworkName.get_emails_network(Snapshot.find(sid).company_id)
    g = Group.find(gid)
    sqlstr = "
        SELECT COUNT(*) AS receiving
        FROM network_snapshot_data AS nsd
        JOIN employees AS inemps ON inemps.id = nsd.to_employee_id
        JOIN employees AS outemps ON outemps.id = nsd.from_employee_id
        JOIN groups AS ingroups ON ingroups.id = inemps.group_id
        JOIN groups AS outgroups ON outgroups.id = outemps.group_id
        WHERE
          (ingroups.nsleft >= #{g.nsleft} AND ingroups.nsright <= #{g.nsright}) AND
          (outgroups.nsleft < #{g.nsleft} OR  outgroups.nsright > #{g.nsright}) AND
          nsd.network_id = #{nid} AND
          nsd.snapshot_id = #{sid} AND
          nsd.company_id = #{cid}"
    res = ActiveRecord::Base.connection.select_all(sqlstr)
    return [{ id: gid, measure: res[0]['receiving']}]
  end

  def external_senders_volume(sid, gid = NO_GROUP, pid = NO_PIN)
    cid = find_company_by_snapshot(sid)
    nid = NetworkName.get_emails_network(Snapshot.find(sid).company_id)
    g = Group.find(gid)
    sqlstr = "
        SELECT COUNT(*) AS sending
        FROM network_snapshot_data AS nsd
        JOIN employees AS inemps ON inemps.id = nsd.from_employee_id
        JOIN employees AS outemps ON outemps.id = nsd.to_employee_id
        JOIN groups AS ingroups ON ingroups.id = inemps.group_id
        JOIN groups AS outgroups ON outgroups.id = outemps.group_id
        WHERE
          (ingroups.nsleft >= #{g.nsleft} AND ingroups.nsright <= #{g.nsright}) AND
          (outgroups.nsleft < #{g.nsleft} OR  outgroups.nsright > #{g.nsright}) AND
          nsd.network_id = #{nid} AND
          nsd.snapshot_id = #{sid} AND
          nsd.company_id = #{cid}"
    res = ActiveRecord::Base.connection.select_all(sqlstr)
    return [{ id: gid, measure: res[0]['sending']}]
  end

  def internal_traffic_volume(sid, gid = NO_GROUP, pid = NO_PIN)
    cid = find_company_by_snapshot(sid)
    nid = NetworkName.get_emails_network(Snapshot.find(sid).company_id)
    g = Group.find(gid)
    sqlstr = "
        SELECT COUNT(*) AS int_traffic
        FROM network_snapshot_data AS nsd
        JOIN employees AS femps ON femps.id = nsd.from_employee_id
        JOIN employees AS temps ON temps.id = nsd.to_employee_id
        JOIN groups AS fgroups ON fgroups.id = femps.group_id
        JOIN groups AS tgroups ON tgroups.id = temps.group_id
        WHERE
          (fgroups.nsleft >= #{g.nsleft} AND fgroups.nsright <= #{g.nsright}) AND
          (tgroups.nsleft >= #{g.nsleft} AND tgroups.nsright <= #{g.nsright}) AND
          nsd.network_id = #{nid} AND
          nsd.snapshot_id = #{sid} AND
          nsd.company_id = #{cid}"
    res = ActiveRecord::Base.connection.select_all(sqlstr)
    return [{ id: gid, measure: res[0]['int_traffic']}]
  end

  def calc_in_the_loop(sid, gid = NO_GROUP, pid = NO_PIN)
    res = []
    cid = find_company_by_snapshot(sid)
    employee_ids = get_inner_select_as_arr(cid, pid, gid)

    sqlstr = "SELECT meeting_attendees.employee_id AS id, COUNT(employee_id) AS measure
              FROM meetings_snapshot_data
              JOIN meeting_attendees ON
                meetings_snapshot_data.id = meeting_attendees.meeting_id
              WHERE meeting_attendees.employee_id IN (#{employee_ids.join(',')}) AND
                snapshot_id = #{sid}
              GROUP BY employee_id"

    count_of_invited = ActiveRecord::Base.connection.exec_query(sqlstr)

    return res if is_retrieved_snapshot_data_empty(count_of_invited, sqlstr)

    return handle_raw_snapshot_data(count_of_invited, employee_ids)
  end

  def calc_rejecters(sid, gid = NO_GROUP, pid = NO_PIN)
    res = []
    cid = find_company_by_snapshot(sid)
    employee_ids = get_inner_select_as_arr(cid, pid, gid)

    count_of_invited = calc_in_the_loop(sid, gid, pid)

    # Get meeting count for attendees with a declined response
    sqlstr = "SELECT meeting_attendees.employee_id as id, COUNT(employee_id) as measure
              FROM meetings_snapshot_data
              JOIN meeting_attendees ON
              meetings_snapshot_data.id = meeting_attendees.meeting_id
              WHERE meeting_attendees.employee_id IN (#{employee_ids.join(',')}) AND
              snapshot_id = #{sid} AND
              response = #{DECLINE}
              GROUP BY employee_id"

    count_of_rejected = ActiveRecord::Base.connection.exec_query(sqlstr)

    return res if is_retrieved_snapshot_data_empty(count_of_rejected, sqlstr)

    res = calc_relative_measure_by_key(handle_raw_snapshot_data(count_of_rejected, employee_ids), count_of_invited, 'id', 'measure')
    return res
  end

  def calc_routiners(sid, gid = NO_GROUP, pid = NO_PIN)
    res = []
    cid = find_company_by_snapshot(sid)
    employee_ids = get_inner_select_as_arr(cid, pid, gid)

    count_of_invited = calc_in_the_loop(sid, gid, pid)

    sqlstr = "SELECT meeting_attendees.employee_id as id, COUNT(employee_id) as measure
              FROM meetings_snapshot_data
              JOIN meeting_attendees ON
              meetings_snapshot_data.id = meeting_attendees.meeting_id
              WHERE meeting_attendees.employee_id IN (#{employee_ids.join(',')}) AND
              snapshot_id = #{sid} AND
              meeting_type = #{RECCURING}
              GROUP BY employee_id"

    count_of_recurring = ActiveRecord::Base.connection.exec_query(sqlstr)

    return res if is_retrieved_snapshot_data_empty(count_of_recurring, sqlstr)

    res = calc_relative_measure_by_key(handle_raw_snapshot_data(count_of_recurring, employee_ids), count_of_invited, 'id', 'measure')
    return res
  end

  def calc_inviters(sid, gid = NO_GROUP, pid = NO_PIN)
    cid = find_company_by_snapshot(sid)
    employee_ids = get_inner_select_as_arr(cid, pid, gid)

    sqlstr = "SELECT organizer_id as id, COUNT(organizer_id) as measure
              FROM meetings_snapshot_data
              WHERE organizer_id IN (#{employee_ids.join(',')}) AND
              snapshot_id = #{sid}
              GROUP BY organizer_id"

    count_of_organized_raw = ActiveRecord::Base.connection.exec_query(sqlstr)

    return [] if is_retrieved_snapshot_data_empty(count_of_organized_raw, sqlstr)

    return handle_raw_snapshot_data(count_of_organized_raw, employee_ids)
  end

  def calc_avg_num_of_ppl_in_meetings(sid, gid = NO_GROUP, pid = NO_PIN)
    employee_ids = Employee.where(group_id: gid).pluck(:id)

    sqlstr = "SELECT meeting_id, COUNT(meeting_id) as measure
              FROM meeting_attendees
              WHERE employee_id IN (#{employee_ids.join(',')}) AND NOT
              response = #{DECLINE}
              GROUP BY meeting_id"

    num_of_ppl_in_meetings = symbolize_hash_arr(ActiveRecord::Base.connection.exec_query(sqlstr))

    total_participants_in_meetings = 0
    average_participants_in_meetings = -1

    num_of_ppl_in_meetings.each {|r| total_participants_in_meetings += r[:measure].to_i}

    average_participants_in_meetings = (total_participants_in_meetings.to_f/num_of_ppl_in_meetings.count).round(2)

    return [{id: gid,
             measure: average_participants_in_meetings,
             numerator: total_participants_in_meetings.to_f,
             denominator: num_of_ppl_in_meetings.count}]
  end

  def recurring_meetings_measure(sid, gid = NO_GROUP, pid = NO_PIN)
    employee_ids = Group.find(gid).extract_employees

    sqlstr = "SELECT SUM(duration_in_minutes) AS sum, emps.id AS empid
              FROM meetings_snapshot_data AS msd
              JOIN meeting_attendees AS ma ON msd.id = ma.meeting_id
              JOIN employees AS emps ON emps.id = ma.employee_id
              WHERE
                ma.employee_id IN (#{employee_ids.join(',')}) AND NOT
                response = #{DECLINE} AND
                meeting_type = 1
              GROUP BY empid"

    res = ActiveRecord::Base.connection.exec_query(sqlstr).to_hash

    ret = []
    res.each do |r|
      ret << {id: r['empid'], measure: r['sum'].to_f.round(2)}
    end
    ret = result_zero_padding(employee_ids, ret)
    return ret
  end

  #############################################################################
  # This algorithm is similar to avg_time_spent_in_meetings_gauge, only
  # difference is it counts # per employe (measure, not a gauge).
  # It is needed for the leaderboard
  #############################################################################
  def time_spent_in_meetings_measure(sid, gid = NO_GROUP, pid = NO_PIN)
    employee_ids = Group.find(gid).extract_employees

    sqlstr = "SELECT SUM(duration_in_minutes) AS sum, emps.id AS empid
              FROM meetings_snapshot_data AS msd
              JOIN meeting_attendees AS ma ON msd.id = ma.meeting_id
              JOIN employees AS emps ON emps.id = ma.employee_id
              WHERE ma.employee_id IN (#{employee_ids.join(',')}) AND NOT
              response = #{DECLINE}
              GROUP BY empid"

    res = ActiveRecord::Base.connection.exec_query(sqlstr).to_hash

    ret = []
    res.each do |r|
      ret << {id: r['empid'], measure: r['sum'].to_f.round(2)}
    end
    ret = result_zero_padding(employee_ids, ret)
    return ret
  end

  #############################################################################
  # This algorithm is very similar to time_spent_in_meetings_measure. The
  # difference is it is a gauge, not a measure.
  # It is used by the main stats panel and the number is also displayed in the
  # main widget.
  #############################################################################
  def avg_time_spent_in_meetings_gauge(sid, gid = NO_GROUP, pid = NO_PIN)
    employee_ids = Employee.where(group_id: gid).pluck(:id)
    employee_count = employee_ids.count

    sqlstr = "SELECT meeting_id, duration_in_minutes, COUNT(meeting_attendees.meeting_id) as ppl_count
              FROM meetings_snapshot_data
              JOIN meeting_attendees ON
              meetings_snapshot_data.id = meeting_attendees.meeting_id
              WHERE meeting_attendees.employee_id IN (#{employee_ids.join(',')}) AND NOT
              response = #{DECLINE}
              GROUP BY meeting_id, duration_in_minutes"

    meeting_entries = symbolize_hash_arr(ActiveRecord::Base.connection.exec_query(sqlstr))
    meeting_entries = integerify_hash_arr_all(meeting_entries)

    total_time_spent = 0
    meeting_entries.each do |meeting|
      total_time_spent += meeting[:duration_in_minutes] * meeting[:ppl_count]
    end

    return [{id: nil,
             measure: total_time_spent/employee_count,
             numerator: total_time_spent,
             denominator: employee_count}]
  end
  def calc_max_indegree_for_specified_matrix(snapshot_id, matrix_name)
    result_vector = calc_degree_for_specified_matrix(snapshot_id, matrix_name, EMAILS_IN, INSIDE_GROUP, -1, -1)
    calc_max_vector(result_vector)
  end

  def calc_relative_measure_by_key(numerator_arr, denominator_arr, key, value)
    res = []
    stringified_numerator_arr = stringify_hash_arr(numerator_arr)
    stringified_denominator_arr = stringify_hash_arr(denominator_arr)

    stringified_numerator_arr.each do |numerator|
      stringified_denominator_arr.each do |denominator|
        if(numerator[key].to_i == denominator[key].to_i)
          next if numerator[value].nil?
          res << { key => numerator[key].to_i, value => denominator[value] != 0 ? (numerator[value].to_f/denominator[value]).round(2) : -1000000.0 }
        end
      end
    end
    return symbolize_hash_arr(res)
  end

  # Common functionality for handling raw data for measure algorithms
  def handle_raw_snapshot_data(raw_object_array, employee_ids)
    array = []

    raw_object_array.each{|obj| array << obj.to_hash}
    # array = integerify_hash_arr(array)
    array = integerify_hash_arr_all(array)

    return result_zero_padding(employee_ids, array)
  end

  ################ Utilities ###########################################
  def self.get_members_in_group(pinid, gid, sid)
    return Group.find(gid).extract_employees if pinid == NO_PIN && gid != NO_GROUP
    return CdsPinsHelper.get_inner_select_by_pin_as_arr(pinid) if pinid != NO_PIN && gid == NO_GROUP
    if pinid == NO_PIN && gid == NO_GROUP
      return Employee.by_snapshot(sid).pluck(:id)
    end
    return nil
  end

  ##################################################################################
  # Utility function to add numbers by same index in different hashes in the array
  #
  # +array+:: array to add and  minimize
  # +key+:: key by which to minimize values
  # +value+:: value to sum
  # 
  # Example: calling sum_and_minimize_array_of_hashes_by_key(array, 'id', 'num') 
  # where array is = [{id: 1, num: 2},{id: 2, num: 10},{id: 1, num: 3},{id: 2, num: 8}]
  # will return: [{id: 1, num: 5},{id: 2, num: 18}]
  #
  # Notice the addition for the 1st and 3rd hash was: 2+3, and the addition for
  # the 2nd and 4th was 10+8.
  ##################################################################################
  def sum_and_minimize_array_of_hashes_by_key(array, key, value)
    temp = []
    result = []
    stringified_array = stringify_hash_arr(array)

    stringified_array.each do |entry|
      temp[entry[key]] = 0 if temp[entry[key]].nil?
      temp[entry[key]] += entry[value]
    end
    temp.each_with_index { |entry, index| result << { key => index, value => entry } unless entry.nil? }

    return symbolize_hash_arr(result)
  end

  def stringify_hash_arr(hash_array)
    arr = []
    hash_array.each{|entry| arr << entry.stringify_keys}
    return arr
  end

  def symbolize_hash_arr(hash_array)
    arr = []
    hash_array.each{|entry| arr << entry.symbolize_keys}
    return arr
  end

  # Convert values of field to integers
  # +hash_array+:: array of hashes
  # +key+:: key of field to convert
  # Example: for key= 'measure' - {:id=>1004, :measure=>"1"} will return {:id=>1004, :measure=>1}
  def integerify_hash_arr_by_key(hash_array, key)
    res = []
    temp = stringify_hash_arr(hash_array)
    temp.each do |r|
      r[key] = r[key].to_i
      res << r
    end
    return symbolize_hash_arr(res)
  end

  # Convert all values of hashes to integers
  # +hash_array+:: array of hashes
  def integerify_hash_arr_all(hash_array)
    res = hash_array
    hash_array.each do |h|
      keys = h.stringify_keys.keys
      keys.each do|key|
        res = integerify_hash_arr_by_key(res, key)
      end
    end
    return res
  end

  def is_retrieved_snapshot_data_empty(entries, query)
    if(entries.count == 0)
      #puts ">>> No snapshot data for this query:\n#{query}"
      return true
    end
    return false
  end

  def self.get_relation_arr(_pid, _gid, snapshot, network_id)
    return "select from_employee_id, to_employee_id from network_snapshot_data where value = 1
    AND snapshot_id = #{snapshot} AND network_id = #{network_id}"
  end


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
  ################################### Boolean network helper functions ##################################
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
    return NetworkSnapshotData.connection.select_all(query)
  end
end

def find_company_by_snapshot(snapshot_id)
  Snapshot.where(id: snapshot_id).first.company_id
end
