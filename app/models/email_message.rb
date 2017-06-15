class EmailMessage < ActiveRecord::Base
  belongs_to :questionnaire_participant

  def mark_as_pending
    self.pending = true
  end

  def send_email
    self.sent_at = DateTime.now
    update(pending: false)
  end
end
