require './app/helpers/dfs_helper.rb'
module TrustHelper
  include PinsHelper
  include GroupsHelper
  include SelectionHelper
  include DfsHelper

  NO_PIN   ||= -1
  NO_GROUP ||= -1
  ID       ||= 0
  MEASURE  ||= 1

  OUT ||= 'employee_id'
  IN  ||= 'trusted_id'

  def calculate_pair_trusted_per_snapshot(snapshot_id, pid = NO_PIN, gid  = NO_GROUP)
    inner_select = get_inner_select(pid, gid)
    query = get_trusted_relations_arr(pid, gid, snapshot_id)
    snapshot = Snapshot.where(id: snapshot_id).last
    dt = snapshot.timestamp.to_i
    unless inner_select.nil?
      query += "and employee_id in (#{inner_select} ) " \
      "and trusted_id in (#{inner_select}) "
    end
    temp_res = ActiveRecord::Base.connection.select_all(query)
    return format_to_analyze(temp_res, dt)
  end

  def get_t_in_n(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    t_in = get_t(snapshot_id, IN, pid, gid)
    return format_trust_scores(t_in, snapshot_id, pid, gid)
  end

  def get_t_out_n(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    t_out = get_t(snapshot_id, OUT, pid, gid)
    return format_trust_scores(t_out, snapshot_id, pid, gid)
  end

  private

  def format_trust_scores(t, snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    company_id = Snapshot.where(id: snapshot_id).first.company_id
    unit_size = get_unit_size(company_id, pid, gid)
    fail 'No Employees found!' if unit_size == 0
    t.rows.each do |row|
      val = row[MEASURE].to_f / unit_size
      row[MEASURE] = val.round(2)
    end
    format_from_activerecord_result(t)
  end

  def get_trusted_relations_arr(_pid, _gid, snapshot)
    return "select employee_id, trusted_id from trusts_snapshots where trust_flag = 1
    AND snapshot_id = #{snapshot} "
  end

  def format_to_analyze(ar, dt)
    ret = []
    ar.rows.each do |row|
      ret << { from_emp_id: row[ID].to_i, to_emp_id: row[MEASURE].to_i, weight: 1, dt: dt * 1000 }
    end
    return ret
  end

  def get_t(snapshot_id, groupby, pid = NO_PIN, gid = NO_GROUP)
    inner_select = get_inner_select(pid, gid)
    query = "SELECT #{groupby}, sum(trust_flag)  from trusts_snapshots " + "where snapshot_id = #{snapshot_id} "
    unless inner_select.blank?
      query += "and employee_id in (#{inner_select}) " \
               "and trusted_id in (#{inner_select}) "
    end
    query += " group by #{groupby} order by sum(trust_flag) asc"
    return ActiveRecord::Base.connection.select_all(query)
  end
end
