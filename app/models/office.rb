class Office < ActiveRecord::Base
  has_many :employees
  belongs_to  :company

  validates :company_id, presence: true
  validates :name, presence: true, length: { maximum: 50 }
end
