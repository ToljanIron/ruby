class EventType < ActiveRecord::Base
  validates :name, presence: true

  def self.create_job_event(event_name, created_at = Time.zone.now)
    create(name: event_name.to_s, created_at: created_at)
  end
end
