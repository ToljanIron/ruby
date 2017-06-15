class EmployeeAttributesController < ApplicationController
    # require "csv"
  
  def export_to_csv
    authorize :employee, :index?
    snapshot_id = params["snapshot_id"]
    company = Company.find_by(id: current_user.company_id)
    if snapshot_id
      employees_data = EmployeeAttribute.where(snapshot_id: snapshot_id)
    else
      emp_ids = company.employees.pluck(:id)
      employees_data = EmployeeAttribute.where(employee_id: emp_ids)
    end
    employees_data = EmployeeAttributesHelper.convert_to_array(employees_data)
    file_path = "#{Rails.root}/tmp/employee attributes for #{company.name}.csv"
    file = CSV.open(file_path,  "wb",
      :write_headers=> true,
      headers:['Employee Name', 'Role', 'Email', 'External domain emails', 'Snapshot', 'No. of emails send', 'Domain'],
      ) do |csv|
      employees_data.each do |emp_data|
        csv << emp_data
      end
    end
    file = File.open(Rails.root.join('tmp', file_path), "rb")
    contents = file.read
    File.delete(file_path) if File.exist?(file_path)
    send_data(contents, :filename => "employee attributes for #{company.name}.csv", encoding: 'utf8', type: 'application/vnd.ms-excel', disposition: 'attachment')
    # send_file(Rails.root.join('tmp', file_path), encoding: 'utf8', type: 'application/vnd.ms-excel', disposition: 'attachment')
  end

end
