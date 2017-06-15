class RawDataEntry < ActiveRecord::Base
  validates :msg_id, presence: true
  validates :from, presence: true
end
