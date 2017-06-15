class EmailService < ActiveRecord::Base
  belongs_to :domain

  validates :domain_id, presence: true
  validates :name, presence: true
end
