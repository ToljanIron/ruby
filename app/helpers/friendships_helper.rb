require './app/helpers/groups_helper.rb'
require './app/helpers/util_helper.rb'
require './app/helpers/selection_helper.rb'
module FriendshipsHelper
  include PinsHelper
  include GroupsHelper
  include UtilHelper
  include SelectionHelper

  NO_PIN   ||= -1
  NO_GROUP ||= -1

  ID      ||= 0
  MEASURE ||= 1

  IN  ||= 'friend_id'
  OUT ||= 'employee_id'

  def calculate_pair_friendships_per_snapshot(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    inner_select = get_inner_select(pid, gid)
    snapshot = Snapshot.where(id: snapshot_id).last
    recent_snapshot = snapshot.id
    dt = snapshot.timestamp.to_i
    query = get_relations_arr(pid, gid, recent_snapshot)
    unless inner_select.blank?
      # query += "and employee_id in (#{inner_select} ) " \
      # "and friend_id in (#{inner_select}) "
    end
    temp_res = ActiveRecord::Base.connection.select_all(query)
    return format_to_analyze(temp_res, dt)
  end

  def get_most_social(f_snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    company_id = Snapshot.where('id = ?', f_snapshot_id).first.company_id
    f_in_formatted = format_from_activerecord_result(get_f_in(f_snapshot_id, pid, gid)) # get full list of id: measure:
    all_emps_ids = get_all_emps(company_id, pid, gid)
    res = []
    friend_arr = []
    friend_pairs = calculate_pair_friendships_per_snapshot(f_snapshot_id, pid, gid) # all pairs in friendship
    friend_pairs.each do |pair| # produce array of indegree nodes for every node
      friend_arr[pair[:to_emp_id].to_i] = [] if friend_arr[pair[:to_emp_id].to_i].nil?
      friend_arr[pair[:to_emp_id].to_i].push(pair[:from_emp_id].to_i)
    end
    friend_arr.each_with_index do |from_members_arr, index|
      res << calc_social_per_friend(f_in_formatted, from_members_arr, index) unless from_members_arr.nil?
    end
    # add remainder of employees
    (all_emps_ids - res.map { |emp| emp[:id] }).each { |emp| res << { id: emp, measure: 0.0 } }
    max = get_max(res)
    normalize_by_n(res, max)
    res = res.sort_by { |h| -h[:measure] }
    return res
  end

  def normalize_by_n(res, n)
    if n == 0
      res.each_with_index { |_e, i| (res[i][:measure] = n.round(2)) }
    else
      res.each_with_index { |_e, i| (res[i][:measure] = (res[i][:measure] / n).round(2)) } # replace every measure attribute in the array with its normalized value
    end
  end

  def calc_social_per_friend(f_in, candidate_arr, friend_id)
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
    return { id: friend_id, measure: emp_fin + avg_in }
  end

  def most_isolated(f_snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    res = get_f_in_n(f_snapshot_id, pid, gid)
    max = get_max(res)
    return res if max == -1
    res.each { |o| o[:measure] = max - o[:measure].to_f }
    res = res.sort_by { |h| -h[:measure] }
    return res
  end

  def get_f_in_n(f_snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    company_id = Snapshot.where('id = ?', f_snapshot_id).first.company_id
    f_in = get_f_in(f_snapshot_id, pid, gid)

    unit_size = get_unit_size(company_id, pid, gid)
    f_in_n = f_in
    f_in_n.rows.each do |row|
      if unit_size == 0
        val = 0
      else
        val = row[MEASURE].to_f / unit_size
      end
      row[MEASURE] = val.round(2)
    end
    res = format_from_activerecord_result(f_in_n)
    return res
  end

  def get_f_out_n(f_snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    company_id = Snapshot.where('id = ?', f_snapshot_id).first.company_id
    f_out = get_f_out(f_snapshot_id, pid, gid)

    unit_size = get_unit_size(company_id, pid, gid)
    f_out_n = f_out
    f_out_n.rows.each do |row|
      if (unit_size == 0)
        val = 0
      else
        val = row[MEASURE].to_f / unit_size
      end
      row[MEASURE] = val.round(2)
    end
    res = format_from_activerecord_result(f_out_n)
    return res
  end

  def format_to_analyze(ar)
    ret = []
    ar.rows.each do |row|
      ret << { from_emp_id: row[ID].to_i, to_emp_id: row[MEASURE].to_i, weight: 1, dt: dt * 1000 }
    end
    return ret
  end

  private

  def get_f_in(f_snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    return get_f(f_snapshot_id, IN, pid, gid)
  end

  def get_f_out(f_snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    return get_f(f_snapshot_id, OUT, pid, gid)
  end

  def get_f(f_snapshot_id, groupby, pid = NO_PIN, gid = NO_GROUP)
    inner_select = get_inner_select(pid, gid)
    # query = "select #{groupby}, sum(friend_flag)  from friendships_snapshots " \
    # "where snapshot_id = #{f_snapshot_id} "
    # unless inner_select.blank?
    #   query += "and employee_id in (#{inner_select} ) " \
    #   "and friend_id in (#{inner_select}) "
    # end
    # query += " group by #{groupby} order by sum(friend_flag) desc"
    query = "select * from companies where 1=2"
    return ActiveRecord::Base.connection.select_all(query)
  end


  # def get_relations_arr(_pid, _gid, snapshot)   DEAD CODE ASAF BYEBUG
  #   return "select employee_id, friend_id from friendships_snapshots where friend_flag = 1
  #   AND snapshot_id = #{snapshot} "
  # end

  def get_relations_arr(_pid, _gid, snapshot) 
    return "select * from companies where 1=2"
  end



  def get_all_emps(cid, pid, gid)
    if pid == NO_PIN && gid != NO_GROUP
      group = Group.find(gid)
      empsarr = group.extract_employees
      return empsarr
    end
    if pid != NO_PIN && gid == NO_GROUP
      return EmployeesPin.where(pin_id: pid).pluck(:employee_id)
    end
    if pid != NO_PIN && gid != NO_GROUP
      fail 'Ambiguous sub-group request with both pin-id and group-id'
    end
    return Employee.where(company_id: cid).pluck(:id)
  end
end
