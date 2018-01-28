class Alert < ActiveRecord::Base
  belongs_to :company
  belongs_to :snapshot
  belongs_to :company_metric
  belongs_to :employee
  belongs_to :group

  enum state: [:pending, :viewed, :discarded]
  enum direction: [:na, :good, :bad]

  scope :by_snapshot, ->(sid) {
    Alert.where(snapshot_id: sid)
  }

  ################ Operations on alerts #########################
  def discard
    update!(state: :discarded)
  end

  def mark_viewed
    update!(state: :viewed)
  end

  def self.alerts_for_snapshot(cid, sid, gids = [])
    ret = Alert
      .select("mn.name AS metric_name, alerts.group_id, alerts.employee_id, alert_type, direction, state")
      .joins('LEFT JOIN groups AS g ON g.id = alerts.group_id')
      .joins('LEFT JOIN employees AS emps ON emps.id = alerts.employee_id')
      .joins('LEFT JOIN company_metrics AS cm ON cm.id = alerts.company_metric_id')
      .joins('LEFT JOIN metric_names AS mn ON mn.id = cm.metric_id')
      .where(state: ['pending','viewed'])
      .where(company_id: cid, snapshot_id: sid)
    ret = ret.where(group_id: gids) if gids.length > 0
    return ret
  end
end
