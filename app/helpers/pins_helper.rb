module PinsHelper
  def create_pin(pin_name, pin_definition)
    criteria = transform_to_wherepart pin_definition
    Pin.create(pin_name, criteria)
  end

  def transform_to_wherepart(conds)
    fail "Can't create pin with null conditions" if conds.nil? || conds == {}
    conds_str = create_conditions_part(conds[:conditions] || conds['conditions'])
    emps_str  = create_employees_part(conds[:employees] || conds['employees'])
    groups_str = create_groups_part(conds[:groups] || conds['groups'])
    cretria = nil
    !cretria.nil? ? cretria += "#{conds_str}" : cretria = conds_str unless conds_str.nil?
    !cretria.nil? ? cretria += " or #{emps_str}" : cretria = emps_str  unless emps_str.nil?
    !cretria.nil? ? cretria += " or #{groups_str}" : cretria = groups_str unless groups_str.nil?
    return cretria
  end

  def get_inner_select_by_pin(pinid)
    return nil if pinid == -1
    return "select employee_id from employees_pins where pin_id = #{pinid}"
  end

  def get_inner_select_by_pin_as_arr(pinid)
    return nil if pinid == -1
    return EmployeesPin.where(pin_id: pinid).select(:employee_id).map { |entry| entry.employee_id }
  end

  def delete_pin(id)
    res = 'Fail'
    return nil unless id
    ActiveRecord::Base.transaction do
      begin
        pin_to_delete = Pin.find(id)
        unless pin_to_delete.nil?
          pin_to_delete.update_attribute(:active, false)
          EmployeesPin.delete_all("pin_id = #{pin_to_delete.id}")
          res = 'OK'
        end
      rescue => e
        _error = e.message
      end
    end
    return res
  end

  def add_status_to_new_pin(action_button)
    if action_button == SAVED_AS_DRAFT
      status = :draft
    elsif action_button == GENERATE
      status = :pre_create_pin
    end
    return status
  end

  def create_condition_list(conditions)
    conditions_to_preset = []
    conditions.each do |cond|
      condition = {}
      case cond['param']
      when 'gender'
        condition[:param] = 'gender'
        condition[:vals] = get_gender(cond['vals'])
      when 'rank' || 'rank_2'
        condition[:param] = 'rank_id'
        condition[:vals] = get_ids_from_satellite_table(cond['vals'], Rank, false)
      when 'office'
        condition[:param] = 'office_id'
        condition[:vals] = get_ids_from_satellite_table(cond['vals'], Office)
      when 'role_type'
        condition[:param] = 'role_id'
        condition[:vals] = get_ids_from_satellite_table(cond['vals'], Role, false)
      when 'marital_status'
        condition[:param] = 'marital_status_id'
        condition[:vals] = get_ids_from_satellite_table(cond['vals'], MaritalStatus, false)
      when 'age_group'
        condition[:param] = 'age_group_id'
        condition[:vals] = get_ids_from_satellite_table(cond['vals'], AgeGroup, false)
      when 'seniority'
        condition[:param] = 'seniority_id'
        condition[:vals] = get_ids_from_satellite_table(cond['vals'], Seniority, false)
      end
      conditions_to_preset.push(condition) unless condition.empty?
    end
    return conditions_to_preset
  end

  private

  def create_conditions_part(conditions)
    return nil if conditions.nil? || conditions.length == 0
    conds_str = '(1=1 '
    conditions.map do |cond|
      vals = (cond[:vals] || cond['vals']).join(',')
      op = (cond[:oper] || cond['oper'])
      oper = operation(op)
      param = (cond[:param] || cond['param'])
      conds_str += "and #{param} #{oper} (#{vals}) "  unless vals.nil? || vals.length == 0
    end
    return conds_str + ')'
  end

  def create_employees_part(employees)
    return nil if employees.nil? || employees.empty?
    emps_str = 'email in ('
    employees.map do |emp|
      emps_str += "'#{emp}', "
    end
    return emps_str[0..-3] + ')'
  end

  def create_groups_part(groups)
    return nil if groups.nil? || groups.empty?
    groups_str = 'group_id in ('
    groups.map do |group|
      groups_str += "#{group},"
    end
    return groups_str[0..-2] + ')'
  end

  def get_gender(vals)
    res = []
    vals.each do |val|
      if val == 'male'
        res.push(0)
      else
        res.push(1)
      end
    end
    return res
  end

  def get_ids_from_satellite_table(vals, satellite_table, with_company = true)
    res = []
    vals.each do |val|
      if with_company
        current_id = satellite_table.where(name: val, company_id: current_user.company_id).first.try(:id)
      else
        current_id = satellite_table.where(name: val).first.try(:id)
      end
      res.push(current_id) if current_id
    end
    return res
  end

  def operation(op)
    return 'not in' if op == 'notin'
    return 'in' if op == 'in' || op.nil? || op == ''
    fail  "Illegal operation: #{op} when evaluating conditions set for a pin"
  end
end
