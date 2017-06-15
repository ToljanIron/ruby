module PreCalculatePinsHelper
  NO_COMPANY = -1
  def get_employees(pin)
    json = pin.pack_to_json
    wherepart = transform_to_wherepart(json[:definition])
    return Employee.where(wherepart).where(company_id: pin.company_id)
  end

  def find_pins(company_id)
    return Pin.where(active: true, company_id: company_id) if company_id.to_i != NO_COMPANY
    return Pin.where(active: true)
  end

  def save_employees_to_pin(pin, emps)
    pinid = pin.id
    ActiveRecord::Base.transaction do
      begin
        EmployeesPin.delete_all("pin_id = #{pinid}")
        emps.each do |emp|
          EmployeesPin.create(pin_id: pinid, employee_id: emp.id)
        end
        pin.update_attribute(:status, :priority)
      rescue Exception => e
        puts "pre_calculate ERROR: Failed to update pin: #{pinid}, received message: #{e.message}"
        puts e.backtrace.join("\n")
        raise ActiveRecord::Rollback
        return false
      end
    end
    return true
  end
end
