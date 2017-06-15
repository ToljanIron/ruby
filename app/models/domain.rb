class Domain < ActiveRecord::Base
  belongs_to :company

  validates :domain, presence: true
  validates :company_id, presence: true
  validates_uniqueness_of :domain
end
