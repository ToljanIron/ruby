module ApiClientConfigurationHelper
  def valid_active_time_start?(str)
    return valid_time_format? str
  end

  def valid_active_time_end?(str)
    return valid_time_format? str
  end

  def valid_log_max_size_in_mb?(str)
    return valid_int? str
  end

  def valid_disk_space_limit_in_mb?(str)
    return valid_int? str
  end

  def valid_duration_of_old_logs_by_months?(str)
    return valid_int? str
  end

  def valid_wakeup_interval_in_seconds?(str)
    return valid_int? str
  end

  def valid_active?(str)
    return str.downcase == 'true' || str.downcase == 'false'
  end

  def valid_serial?(str)
    return str.is_a?(String) && str.size > 0
  end

  private

  def valid_time_format?(str)
    rgx = /^\d\d:\d\d$/
    return false unless (str =~ rgx) == 0
    arr = str.split(':')
    d1 = arr[0]
    d2 = arr[1]
    return false if d1.to_i > 23
    return false if d2.to_i > 59
    return true
  end

  def valid_int?(str)
    rgx = /^\d+$/
    return false unless (str =~ rgx) == 0
    return str.to_i > 0
  end
end
