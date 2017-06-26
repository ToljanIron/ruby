module EmployeesHelper
  DIRECT_MANAGER = 0
  PRO_MANAGER = 1

  def check_enums(processed_attrs, errors)
    if !Employee.genders.keys.include? processed_attrs[:gender]
      errors.push 'gender'
      processed_attrs[:gender] = nil
    end
    return
  end

  def valid_attr_field(attr_field)
    return attr_field && !attr_field.empty?
  end
end
