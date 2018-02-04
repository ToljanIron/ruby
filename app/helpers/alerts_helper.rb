# frozen_string_literal: true
module AlertsHelper

  def self.format_alerts(alerts)
    ret = alerts.map do |a|
      e = {}
      e[:alid] = a[:id]
      e[:heading] = "#{a[:group_name]} - #{a[:metric_name]}"
      e[:text] = "#{a[:group_name]} has #{a[:direction]} percentage of #{a[:metric_name]}"
      e[:state] = a[:state]
      e
    end
    return ret
  end
end
