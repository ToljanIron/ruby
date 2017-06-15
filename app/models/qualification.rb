class Qualification < ActiveRecord::Base
  validates :company_id, presence: true
  validates :name, presence: true, length: { maximum: 50 }
end
