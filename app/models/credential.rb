class Credential < ActiveRecord::Base
  validates :company_id, presence: true
end
