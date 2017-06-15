# frozen_string_literal: true
class CompanyMetric < ActiveRecord::Base
  has_one :algorithm_type
  belongs_to :algorithm
  belongs_to :metric_name,         foreign_key: :metric_id
  belongs_to :gauge_configuration, foreign_key: :gauge_id
  belongs_to :network, foreign_key: :network_id, class_name: 'NetworkName'

  validates :algorithm_type_id, presence: true
  validates :network_id, presence: true
  validates :algorithm_id, presence: true

  def company_metric
    return CompanyMetric.find_by(id: analyze_company_metric_id)
  end

  def self.generate_metric_name_for_questionnaire_only(network_name, aid)
    return "#{network_name}-In"  if aid.to_s == '601'
    return "#{network_name}-Out" if aid.to_s == '602'
    return 'NA'
  end

  def self.generate_ui_level_id_for_questionnaire_only(id)
    return id.to_i + 10
  end
end
