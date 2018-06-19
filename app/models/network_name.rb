# frozen_string_literal: true
class NetworkName < ActiveRecord::Base
  belongs_to :company
  validates :company_id, uniqueness: { scope: [:name, :questionnaire_id] }
  has_many :network_snapshot_data
  has_many :company_metric

  def self.get_emails_network(cid)
    return NetworkName.where(company_id: cid, name: 'Communication Flow').last.id
  end
end
