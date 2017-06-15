class MetricName < ActiveRecord::Base
  belongs_to :company
  has_many :company_metric
end
