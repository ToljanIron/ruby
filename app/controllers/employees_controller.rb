require 'oj'
require 'oj_mimic_json'

include SessionsHelper
include CdsUtilHelper

class EmployeesController < ApplicationController
  DIRECT = 0
  PROFESSIONAL = 1

  def list_managers
    authorize :employee_management_relation, :index?
    cid = current_user.company_id
    sid = sanitize_id(params[:sid]).to_i
    sid ||= Snapshot.last_snapshot_of_company(cid)
    cache_key = "list_managers-#{cid}-#{sid}"
    res = cache_read(cache_key)
    if res.nil?
      res = []

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
