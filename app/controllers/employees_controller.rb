include SessionsHelper
include EmployeesHelper
include UtilHelper

class EmployeesController < ApplicationController
  DIRECT = 0
  PROFESSIONAL = 1

  def list_employees
    authorize :employee, :index?
    company_id = current_user.company_id
    cache_key = "employees-company_id-#{company_id}"
    res = cache_read(cache_key)
    if res.nil?
      res = []
      emp_arr = empscope.includes(:role).includes(:rank).includes(:age_group).includes(:group).includes(:job_title).includes(:marital_status).includes(:office).includes(:seniority)

      sqlstr =
        "select emp.id, CONCAT(man.first_name, ' ', man.last_name) as manager_name, man.id as manager_id
         from employees as emp
         join employee_management_relations as emr on emr.employee_id = emp.id
         join employees as man on man.id = emr.manager_id
         where emp.company_id = #{company_id} and relation_type = #{DIRECT}"
      sqlres = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
      managers_hash = {}
      sqlres.each do |e|
        managers_hash[e['id']] = {manager_name: e['manager_name'], manager_id: e['manager_id']}
      end

      emp_arr.each do |e|
        res.push e.pack_to_json(managers_hash)
      end
      cache_write(cache_key, res)
    end
    render json: { employees: res }, status: 200
  end

  def list_managers
    authorize :employee_management_relation, :index?
    company_id = current_user.company_id
    cache_key = "list_managers-#{company_id}"
    res = cache_read(cache_key)
    if res.nil?
      res = []
      managers = EmployeeManagementRelation.where(employee_id: Employee.where(company_id: company_id).ids, relation_type: DIRECT)
      managers.each do |m|
        res.push m.pack_to_json
      end
      cache_write(cache_key, res)
    end
    render json: { managers: res }, status: 200
  end

  private

  def empscope
    EmployeePolicy::Scope.new(current_user, Employee).resolve
  end
end
