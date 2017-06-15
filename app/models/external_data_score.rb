class ExternalDataScore < ActiveRecord::Base
  validates :snapshot_id, presence: true
  validates :external_data_metric_id, presence: true
end
