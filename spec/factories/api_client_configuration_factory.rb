FactoryGirl.define do
  factory :api_client_configuration do
    active_time_start '03:00'
    active_time_end '09:05'
    disk_space_limit_in_mb 100
    wakeup_interval_in_seconds 30
    active true
    report_if_not_responsive_for 10
    serial SecureRandom.hex
  end
end
