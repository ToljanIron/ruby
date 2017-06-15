class Color < ActiveRecord::Base
  has_many :employee_role_type

  validates_uniqueness_of :rgb
end
