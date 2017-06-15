class ExternalDataMetric < ActiveRecord::Base
  validates :external_metric_name, presence: true
  validates :company_id, presence: true
end
