class Friendship < ActiveRecord::Base
  belongs_to :employee_id,   class_name: 'Employee', foreign_key: 'employee_id'
  belongs_to :friend_id,   class_name: 'Employee', foreign_key: 'friend_id'

  has_one :company, through: :employee
end
