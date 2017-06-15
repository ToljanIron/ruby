class EmailSubjectSnapshotData < ActiveRecord::Base
  belongs_to :employee_from,   class_name: 'Employee', foreign_key: 'employee_from_id'
  belongs_to :employee_to,   class_name: 'Employee', foreign_key: 'employee_to_id'
  validates :employee_from_id, presence: true
  validates :employee_to_id, presence: true
end
