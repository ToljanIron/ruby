module UpdateEmployeesInformationHelper
  include UtilHelper
  NO_COMPANY = -1
  def update_employee(cid)
    companies = cid == NO_COMPANY ? Company.all : Company.where(id: cid)
    fail 'No company found!' if companies.empty?
    companies.each do |c|
      employees = Employee.where(company_id: c.id)
      EmployeeManagementRelation.where(manager_id: employees.pluck(:id), relation_type: 2).destroy_all
      employees.each do |emp|
        age = calc_age_from_now emp.date_of_birth
        age_group_id = calc_age_group age
        seniority_id = calc_seniority emp.work_start_date
        l = get_level(emp)
        sub = get_subordinates(emp)
        emp.update_attributes(age_group_id: age_group_id, seniority_id: seniority_id, formal_level: l)
        relations = []
        sub.each do |sub_id|
          relations.push "(#{emp.id}, #{sub_id}, 2)"
        end
        ActiveRecord::Base.connection.execute("INSERT INTO employee_management_relations (manager_id, employee_id, relation_type) VALUES #{relations.join(', ')}") unless relations.empty?
      end
    end
  end
end
