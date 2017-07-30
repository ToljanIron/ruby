include SessionsHelper
include CdsUtilHelper

class EmployeesController < ApplicationController
  DIRECT = 0
  PROFESSIONAL = 1

  def list_employees
    authorize :employee, :index?
    cid = current_user.company_id
    sid = params[:sid].to_i
    sid = sid == 0 ? Snapshot.last_snapshot_of_company(cid) : sid
    cache_key = "employees-company_id-#{cid}-#{sid}"
    res = cache_read(cache_key)
    if res.nil?
      res = []

      # emp_arr = Employee.by_company(cid, sid).includes(:role).includes(:rank).includes(:age_group).includes(:group).includes(:job_title).includes(:marital_status).includes(:office).includes(:seniority)
      emp_arr = policy_scope(Employee).by_company(cid, sid).includes(:role).includes(:rank).includes(:age_group).includes(:group).includes(:job_title).includes(:marital_status).includes(:office).includes(:seniority)
      emp_ids = emp_arr.pluck(:id)

      sqlstr =
        "SELECT emp.id, CONCAT(man.first_name, ' ', man.last_name) AS manager_name, man.id AS manager_id
         FROM employees AS emp
         JOIN employee_management_relations AS emr ON emr.employee_id = emp.id
         JOIN employees AS man ON man.id = emr.manager_id
         WHERE emp.id IN (#{emp_ids.join(',')}) AND
               emp.company_id = #{cid} AND
               relation_type = #{DIRECT} AND
               emp.snapshot_id = #{sid}"

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

      # managers = EmployeeManagementRelation.where(
      #              employee_id: Employee.by_company(cid, sid).ids,
      #              relation_type: DIRECT)
      managers = EmployeeManagementRelation.where(
                   employee_id: policy_scope(Employee).by_company(cid, sid).ids,
                   relation_type: DIRECT)
      
      managers.each do |m|
        res.push m.pack_to_json
      end
      cache_write(cache_key, res)
    end
    render json: { managers: res }, status: 200
  end
end
