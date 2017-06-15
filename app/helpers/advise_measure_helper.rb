require './app/helpers/pins_helper.rb'
module AdviseMeasureHelper
  include PinsHelper

  LAST_MONTH  ||= 1
  THREE_MONTH ||= 3
  SIX_MONTH   ||= 6
  RECIVER     ||= 1
  INDEGREE    ||= true
  OUTDEGREE   ||= false
  SENDER      ||= 2
  MAX_EMPLOYEES ||= 100

  NO_PIN   ||= -1
  NO_GROUP ||= -1

  SNAPSHOT_ID ||= 'snapshot_id'

  def create_advice_measure(time_filter, company_id, with_others, pin = -1, gid = -1)
    last_snapshot =  Snapshot.where('company_id=?', company_id).order('created_at').last
    return false if last_snapshot.nil?
    list_of_last_snapshot = get_snapshot_node_list(last_snapshot.id, with_others, pin, gid)
    return false if list_of_last_snapshot.rows.length == 0
    snapshot_list_of_comapny = Snapshot.where('company_id=?', company_id).order('created_at')
    snapshot_list_length  = snapshot_list_of_comapny.length - 1
    case time_filter
    when LAST_MONTH
      snapshot_of_pin_type = (snapshot_list_of_comapny.length <= 1) ?  snapshot_list_of_comapny[0] : snapshot_list_of_comapny[snapshot_list_length - LAST_MONTH]
    when THREE_MONTH
      snapshot_of_pin_type = (snapshot_list_of_comapny.length <= 3) ? snapshot_list_of_comapny[0] : snapshot_list_of_comapny[snapshot_list_length - THREE_MONTH]
    when SIX_MONTH
      snapshot_of_pin_type = (snapshot_list_of_comapny.length <= 6) ? snapshot_list_of_comapny[0] : snapshot_list_of_comapny[snapshot_list_length - SIX_MONTH]
    else
      fail 'ERROR - NOT CORRECT PIN'
    end
    list_of_pin_type_snapshot = get_snapshot_node_list(snapshot_of_pin_type.id, with_others, pin, gid)
    user_list = calculate_delta(list_of_last_snapshot, list_of_pin_type_snapshot)
    top_indegree = create_top_indegree(MAX_EMPLOYEES, user_list)
    top_outdegree = create_top_outdegree(MAX_EMPLOYEES, user_list)
    return { top_outdegree: top_outdegree, top_indegree: top_indegree }
  end

  def add_uninvolved_users(user_list, pin, company_id, gid)
    if pin == -1 &&  gid == -1
      employee_list = Employee.where(company_id: company_id)
      rem_emps = employee_list.pluck(:id) - user_list.map { |emp| emp[:id] }
      rem_emps.each do |emp_id|
        user_list << { id: emp_id, measure: 0, rate: 0 }
      end
    elsif pin == -1 && gid != -1
      employee_list = Group.where(id: gid).first.extract_employees
      rem_emps = employee_list - user_list.map { |emp| emp[:id] }
      rem_emps.each do |emp_id|
        user_list << { id: emp_id, measure: 0, rate: 0 }
      end
    elsif pin != -1 && gid == -1
      employee_list = EmployeesPin.where(pin_id: pin).pluck(:employee_id)
      rem_emps = employee_list - user_list.map { |emp| emp[:id] }
      rem_emps.each do |emp_id|
        user_list << { id: emp_id, measure: 0, rate: 0 }
      end
    end
    return user_list
  end

  def create_measure_list(last_snapshot, degree_type, pid, gid, company_id)
    user_list = calculate_delta(last_snapshot, last_snapshot)
    return nil if user_list.length == 0
    if degree_type == INDEGREE
      degree_list = create_top_indegree(MAX_EMPLOYEES, user_list)
      degree_list = add_uninvolved_users(degree_list, pid, company_id, gid)
    else
      degree_list = create_top_outdegree(MAX_EMPLOYEES, user_list)
    end
    return degree_list
  end

  private

  def calculate_delta(list_of_last_snapshot, list_of_pin_type_snapshot)
    user_list = {}
    same_snapshot = same_snapshot?(list_of_last_snapshot, list_of_pin_type_snapshot)
    list_of_last_snapshot.each do |node|
      delta = 0

      fid = node['employee_from_id']
      tid = node['employee_to_id']
      current_node = { sender: "#{fid}", receiver: "#{tid}", delta: 0 }
      if !same_snapshot
        relation_from_pin_type_snapshot = nil
        list_of_pin_type_snapshot.map do |relation|
          relfid = relation[:employee_from_id]
          reltid = relation[:employee_to_id]
          relation_from_pin_type_snapshot = relation if relfid == fid && reltid == tid
        end

        if !relation_from_pin_type_snapshot.nil?
          (1..18).each do |i|
            delta += (node['n' + i.to_s].to_i - relation_from_pin_type_snapshot['n' + i.to_s].to_i)
          end
        else
          (1..18).each do |i|
            delta += (node['n' + i.to_s].to_i)
          end
        end
      else
        (1..18).each do |i|
          delta += (node['n' + i.to_s].to_i)
        end
      end
      current_node[:delta] = delta
      user_list = add_delta_to_user(fid, delta, SENDER, user_list)
      user_list = add_delta_to_user(tid, delta, RECIVER, user_list)
    end
    return user_list
  end

  def add_delta_to_user(user_id, delta, user_type, user_list)
    user_list[user_id] = { indegree: 0, outdegree: 0 } if user_list[user_id].nil?
    case user_type
    when RECIVER
      user_list[user_id][:indegree] = user_list[user_id][:indegree] +  delta
    when SENDER
      user_list[user_id][:outdegree] = user_list[user_id][:outdegree] + delta
    end
    return user_list
  end

  def create_top_indegree(number, user_list)
    top_list_indgree = []
    indegree_list = user_list.sort_by { |_key, value | value[:indegree] }.reverse
    last_length_of_list = [indegree_list.length, number].min
    top_indgree = indegree_list[0..last_length_of_list]
    top_indgree = create_normalized(top_indgree, 'indegree')
    top_indgree.each do |user_degree|
      temp = {}
      emp = Employee.find_by(id: user_degree.first)
      temp[:id] = emp.id
      temp[:measure] = user_degree.last[:indegree]
      temp[:rate] = user_degree.last[:rate]
      top_list_indgree.push(temp)
    end
    return top_list_indgree
  end

  def create_top_outdegree(number, user_list)
    top_list_outdegree = []
    outdegree_list = user_list.sort_by { |_key, value | value[:outdegree] }.reverse
    last_length_of_list = [outdegree_list.length, number].min
    top_outdegree = outdegree_list[0..last_length_of_list]
    top_outdegree = create_normalized(top_outdegree, 'outdegree')
    top_outdegree.each do |user_degree|
      temp = {}
      emp = Employee.find_by(id: user_degree.first)
      temp[:id] = emp.id
      temp[:measure] = user_degree.last[:outdegree]
      temp[:rate] = user_degree.last[:rate]
      top_list_outdegree.push(temp)
    end
    return top_list_outdegree
  end

  def same_snapshot?(list_of_last_snapshot, list_of_pin_type_snapshot)
    return true if list_of_pin_type_snapshot.rows.length == 0
    return list_of_last_snapshot.to_json[SNAPSHOT_ID] == list_of_pin_type_snapshot.to_json[SNAPSHOT_ID]
  end

  def create_normalized(list, dgree_type)
    top_list = list.first.last[:"#{dgree_type}"]
    list.first.last[:rate] = 100
    list.each_with_index do |user, index|
      if index > 0
        user_degree = user.last[:"#{dgree_type}"]
        if top_list == 0
          user.last[:rate] = 100
        else
          user.last[:rate] = (user_degree * 100) / top_list
        end
      end
    end
    return  list
  end

  def get_snapshot_node_list(snapshot_id, with_others, pinid = -1, gid = -1)
    inner_select = inner_select_stmt(pinid, gid)
    company_id = Snapshot.find(snapshot_id)[:company_id]
    others = Employee.where(email: 'other@mail.com', company_id: company_id).first
    network = NetworkSnapshotData.emails(company_id)
    query = 'select distinct s.* from network_snapshot_data as s where' \
    " s.snapshot_id = #{snapshot_id}  and network_id = #{network} "
    unless inner_select.blank?
      query += "and s.from_employee_id in (#{inner_select} ) " \
      "and s.to_employee_id in (#{inner_select}) "
    end
    (!with_others && others) && query += " and from_employee_id != #{others.id} and to_employee_id != #{others.id}"
    return ActiveRecord::Base.connection.select_all(query)
  end

  def get_employee_connection(snapshot_id, with_others, employee_id)
    company_id = Snapshot.find(snapshot_id)[:company_id]
    others = Employee.where(email: 'other@mail.com', company_id: company_id).first
    network = NetworkSnapshotData.emails(company_id)
    query = 'select distinct s.* from network_snapshot_data as s where' \
    " s.snapshot_id = #{snapshot_id} and (s.from_employee_id = #{employee_id} or s.to_employee_id = #{employee_id} and network_id = #{network})"
    (!with_others && others) && query += " and from_employee_id != #{others.id} and to_employee_id != #{others.id}"
    return ActiveRecord::Base.connection.select_all(query)
  end

  def inner_select_stmt(pinid, gid)
    return inner_select_by_group(gid) if pinid == NO_PIN && gid != NO_GROUP
    return inner_select_by_pin(pinid) if pinid != NO_PIN && gid == NO_GROUP
    fail 'Ambigouse sub-group request with both pin-id and group-id' if pinid != NO_PIN && gid != NO_GROUP
    return nil
  end

  def inner_select_by_group(gid)
    group = Group.find(gid)
    empsarr = group.extract_employees
    return empsarr.join(',')
  end

  def inner_select_by_pin(pinid)
    return "select employee_id from employees_pins where pin_id = #{pinid}"
  end
end
