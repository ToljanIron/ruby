# frozen_string_literal: true
module AlertsHelper
  ALERT_TYPE_EXTREME_Z_SCORE_FOR_GAUGE        = 1
  ALERT_TYPE_EXTREME_Z_SCORE_FOR_MEASURE      = 2
  ALERT_TYPE_BIG_DELTA_IN_Z_SCORE_FOR_MEASURE = 3

  def self.format_alerts(alerts)
    ret = alerts.map do |a|
      e = {}
      e[:alid] = a[:id]
      e[:heading] = AlertsHelper.create_alert_heading(a)
      e[:text] = AlertsHelper.create_alert_text(a)
      e[:state] = a[:state]
      e
    end
    return ret
  end

  def self.create_alert_text(a)
    at = a[:alert_type]
    if at == ALERT_TYPE_EXTREME_Z_SCORE_FOR_GAUGE || at == ALERT_TYPE_EXTREME_Z_SCORE_FOR_MEASURE
      return "#{a[:group_name]} has #{a[:direction]} percentage of #{a[:metric_name]}"
    elsif at == ALERT_TYPE_BIG_DELTA_IN_Z_SCORE_FOR_MEASURE
      dir = a[:direction] == 'high' ? 'increased' : 'decreased'
      return "Score of: #{a[:metric_name]} for employee: #{a[:emp_name]} in group: #{a[:group_name]} has #{dir} significantly"
    else
      raise "No such alert_type: #{at}"
    end
  end

  def self.create_alert_heading(a)
    at = a[:alert_type]
    if at == ALERT_TYPE_EXTREME_Z_SCORE_FOR_GAUGE || at == ALERT_TYPE_EXTREME_Z_SCORE_FOR_MEASURE
      return "#{a[:group_name]} - #{a[:metric_name]}"
    elsif at == ALERT_TYPE_BIG_DELTA_IN_Z_SCORE_FOR_MEASURE
      return "#{a[:emp_name]} - #{a[:metric_name]}"
    else
      raise "No such alert_type: #{at}"
    end
  end
end
