class ApiClient < ActiveRecord::Base
  validates :token, uniqueness: true

  belongs_to :api_client_configuration

  TOKEN_LIFE = 30.days

  # def alive?
  #   acc = ApiClientConfiguration.where(id: id)
  #   return true if Time.now.to_i - last_contact.to_i < (acc[0]['report_if_not_responsive_for']) * 60
  #   return false
  # end

  def self.create_new_client(client_name)
    ApiClient.create(client_name: client_name, token: SecureRandom.hex(30), expires_on: DateTime.now + TOKEN_LIFE)
  end

  def self.authenticate_client(token)    
    client = ApiClient.where(token: token).first
    return if client.nil?
    client.update_last_contact
    return if client.expires_on < DateTime.now
    return client
  end

  def update_last_contact
    update(last_contact: Time.now)
  end

  def schedule_config_file_update
    t_id = ApiClientTaskDefinition.find_by(name: 'update_config').id
    params = api_client_configuration.pack_to_json.to_s
    sct = ScheduledApiClientTask.create_scheduled_task(
      t_id,
      nil,
      params,
      id
    )
    sct.priority!
    return sct
  end

  def schedule_upload_log
    t_id = ApiClientTaskDefinition.find_by(name: 'upload_log').id
    sct = ScheduledApiClientTask.create_scheduled_task(
      t_id,
      nil,
      nil,
      id
    )
    sct.priority!
    return sct
  end

  def needs_config_sync?(serial)
    return api_client_configuration.serial != serial
  end

  def update_config(json)
    api_client_configuration.update_by_json json
  end
end