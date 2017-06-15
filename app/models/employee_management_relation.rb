class EmployeeManagementRelation < ActiveRecord::Base
  belongs_to :employee, class_name: 'Manager', foreign_key: :manager_id
  belongs_to :employee

  validates :employee_id, presence: true
  validates :relation_type, presence: true
  enum relation_type: [:direct, :professional, :recursive]

  def pack_to_json
    hash = {}
    hash[:employee_id] = employee_id
    hash[:manager_id] = manager_id
    hash[:relation_type] = relation_type
    return hash
  end
end
