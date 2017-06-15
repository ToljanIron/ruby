class Metric < ActiveRecord::Base
  validates :name, presence: true
  validates :index, presence: true
  validates :metric_type, presence: true, inclusion: { in: %w(measure flag analyze group_measure) }
end
