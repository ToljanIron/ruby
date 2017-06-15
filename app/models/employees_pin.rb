class EmployeesPin < ActiveRecord::Base
  scope :size, ->(pinid) { EmployeesPin.where(pin_id: pinid).count }
end
