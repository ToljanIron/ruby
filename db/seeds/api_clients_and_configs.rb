c = ApiClient.create(
  client_name: 'spectory_collector',
  token: 'd65028a43e33af193de01e796d576e1b7e6cac318b15151ea7bba3b84ab6',
  expires_on: Time.now + 1.year
  )

acc = ApiClientConfiguration.create(
  active_time_start: '02:22',
  active_time_end: '02:55',
  disk_space_limit_in_mb: 21,
  wakeup_interval_in_seconds: 100
)

c.update(api_client_configuration_id: acc.id)
