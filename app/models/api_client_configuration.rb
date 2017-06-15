include ApiClientConfigurationHelper
class ApiClientConfiguration < ActiveRecord::Base
  has_one :api_clients

  validates :report_if_not_responsive_for, presence: true


  def pack_to_json
    return {
      active: active || false,
      active_time_start: active_time_start,
      active_time_end: active_time_end,
      disk_space_limit_in_mb: disk_space_limit_in_mb,
      wakeup_interval_in_seconds: wakeup_interval_in_seconds,
      duration_of_old_logs_by_months: duration_of_old_logs_by_months,
      log_max_size_in_mb: log_max_size_in_mb
    }.to_json
  end

  def update_by_json(json)
    # white_list - should allow updates only params that are avaible at db.
    white_list = %w(serial
                    active
                    active_time_start
                    active_time_end
                    disk_space_limit_in_mb
                    log_max_size_in_mb
                    wakeup_interval_in_seconds
                    duration_of_old_logs_by_months)
    h = {}
    white_list.each do |w|
      validator_name = ['valid_', w, '?'].join
      fail "invalid config parameter: #{w}" unless send(validator_name, json[w])
      h[w] = json[w]
    end
    update(h)
  end
end
