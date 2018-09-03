class EventLog < ActiveRecord::Base
  validates :event_type_id,  presence: true
  belongs_to :company

  def self.log_event(hash)
    if hash.key?(:event_type_name) == false
      hash.store(:event_type_name, 'GENERAL_EVENT')
    end
    id_from_table = EventType.find_by(name: hash[:event_type_name]).try(:id) unless Rails.env.test?
    id_from_table ||= 0
    cid = hash[:company_id]
    e = create(
          company_id: cid,
          event_type_id: id_from_table,
          job_id: hash[:job_id],
          message: [hash[:event_type_name], ': ', hash[:message]].join
    )
    return e
  end

  def qqq
    EventLog.create!(message: "QQQQQQQQQQQQ-#{Time.now}", event_type_id: 1)
  end
end
