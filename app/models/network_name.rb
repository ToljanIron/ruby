# frozen_string_literal: true
class NetworkName < ActiveRecord::Base
  belongs_to :company
  validates :company_id, uniqueness: { scope: :name }
  has_many :network_snapshot_data
  has_many :company_metric
end
