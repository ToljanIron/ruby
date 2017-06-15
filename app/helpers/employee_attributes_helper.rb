module EmployeeAttributesHelper

  DOMAIN = 1
  
  def self.convert_to_array(employees_attributes_rows)
    row_data = employees_attributes_rows.map do |emp_attribute|
      res = []
      emp = Employee.find(emp_attribute.employee_id)
      role = emp.role.name if emp.role
      role = 'NA' if !emp.role
      res.push(emp.first_name + ' ' + emp.last_name)
      res.push(role)
      res.push(emp.email)
      res.push(emp_attribute.data1)
      res.push(Snapshot.find_by(id: emp_attribute.snapshot_id).name)
      res.push(emp_attribute.data2)
      res.push(emp_attribute.data1.split('@')[DOMAIN])
      res
    end

  end

end