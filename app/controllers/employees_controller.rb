include SessionsHelper
include EmployeesHelper
include CdsUtilHelper

class EmployeesController < ApplicationController
  DIRECT = 0
  PROFESSIONAL = 1

  def list_employees
    authorize :employee, :index?
    cid = current_user.company_id
    sid = params[:sid].to_i
    sid ||= Snapshot.last_snapshot_of_company(cid)
    cache_key = "employees-company_id-#{cid}-#{sid}"
    res = cache_read(cache_key)
    if res.nil?
      res = []
      emp_arr = Employee.by_company(cid, sid).includes(:role).includes(:rank).includes(:age_group).includes(:group).includes(:job_title).includes(:marital_status).includes(:office).includes(:seniority)

      sqlstr =
        "select emp.id, CONCAT(man.first_name, ' ', man.last_name) as manager_name, man.id as manager_id
         from employees as emp
         join employee_management_relations as emr on emr.employee_id = emp.id
         join employees as man on man.id = emr.manager_id
         where emp.company_id = #{cid} and relation_type = #{DIRECT} and emp.snapshot_id = #{sid}"
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
    cid = current_user.company_id
    sid = params[:sid].to_i
    sid ||= Snapshot.last_snapshot_of_company(cid)
    cache_key = "list_managers-#{cid}-#{sid}"
    res = cache_read(cache_key)
    if res.nil?
      res = []
      managers = EmployeeManagementRelation.where(
                   employee_id: Employee.by_company(cid, sid).ids,
                   relation_type: DIRECT)
      managers.each do |m|
        res.push m.pack_to_json
      end
      cache_write(cache_key, res)
    end
    render json: { managers: res }, status: 200
  end
end
