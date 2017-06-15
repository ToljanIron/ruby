# frozen_string_literal: true
include Mobile::EmployeesHelper
include Mobile::Utils
class Mobile::EmployeesController < Mobile::MobileController
  def remove
    # diactivate_employee_by_id(params[:id].to_i)
    redirect_to select_company_path(tab: 1, id: params[:company_id])
  end

  def all_employees
    token = params[:token]
    emps = hash_employees_of_company_by_token(token)
    if emps
      render json: emps, status: 200
    else
      render status: 500
    end
  end
end
