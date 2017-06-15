module EmployeesHelper
  DIRECT_MANAGER = 0
  PRO_MANAGER = 1

  def check_enums(processed_attrs, errors)
    if !Employee.genders.keys.include? processed_attrs[:gender]
      errors.push 'gender'
      processed_attrs[:gender] = nil
    else
      # processed_attrs[:gender] = processed_attrs[:gender].to_i
    end
    # unless Employee.marital_statuses.values.include? processed_attrs[:marital_status].to_i
    #   errors.push 'marital_status'
    #   processed_attrs[:marital_status] = nil
    # else
    #   processed_attrs[:marital_status] = processed_attrs[:marital_status].to_i
    # end

    return
  end

  def valid_attr_field(attr_field)
    return attr_field && !attr_field.empty?
  end
end
