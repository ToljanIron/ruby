class SaSetupController < ActionController::Base

  def base
    redirect_if_needed
  end

  def server_name_form
    redirect_if_needed
    puts "In SaSetupController - server_name"
  end

  def server_name_set
    params.permit(:serverName)
    server_name = params[:serverName].sanitize_url
    if server_name.nil?
      redirect_to_error("Bad server name: #{params[:serverName]}")
      return
    end

    CompanyConfigurationTable.find_or_create_by(
      key: 'APP_SERVER_NAME',
      value: server_name,
      comp_id: -1
    )
    Company.update(setup_state: :server_name)
    redirect_to controller: 'sa_setup', action: 'base'
  end

  def datetime
    redirect_if_needed
  end

  def datetime_set
    puts "in datetime_set"
    params.permit(:date, :time)

    date = params[:date].sanitize_date
    if date.nil?
      redirect_to_error("Bad date value: #{params[:date]}")
      return
    end

    time = params[:time].sanitize_time
    if time.nil?
      redirect_to_error("Bad time value: #{params[:time]}")
      return
    end

    Company.update(setup_state: :datetime)
    redirect_to controller: 'sa_setup', action: 'base'
  end

  def certs
    redirect_if_needed
    puts "In certs"
  end

  def certs_set
    puts "in certs_set"
    params.permit(:certFile, :keyFile)

    # Save file to /tmp
    cert_file = params[:certFile][:file]
    file_name = cert_file.original_filename
    path = File.join("/tmp", file_name)
    File.open(path, "wb") { |f| f.write(cert_file.read) }

    # Verify file
    is_valid = `openssl x509 -in #{path} -text -noout > /dev/null 2>&1; echo $?;`.to_i === 0
    if !is_valid
      redirect_to_error("Cert file is invalid: #{file_name}")
      return
    end

    # Move file to final location (take this value from ENV)
    if Rails.env.production? || Rails.env.onpremise?
      `nohup scripts/ssl_setup.sh >> /home/app/sa/log/onpremise.log 2>&1 &`
    else
      `nohup scripts/ssl_setup.sh >> /home/app/sa/log/development.log 2>&1 &`
    end

    redirect_to controller: 'sa_setup', action: 'base'
  end

  def form_error
    params.permit(:error_msg)
    @error_msg = params[:error_msg]
  end

  private

  def redirect_to_error(msg)
    redirect_to controller: 'sa_setup', action: 'form_error', error_msg: msg
  end

  def redirect_if_needed
    curr_action = params[:action]
    setup_state = Company.last.setup_state

    case setup_state
    when 'init'
      redirect_to controller: 'sa_setup', action: 'server_name_form' unless curr_action == 'server_name_form'
    when 'server_name'
      redirect_to controller: 'sa_setup', action: 'datetime' unless curr_action == 'datetime'
    when 'datetime'
      redirect_to controller: 'sa_setup', action: 'certs' unless curr_action == 'certs'
    when 'certs'
      redirect_to controller: 'sa_setup', action: 'restart_after_certs' unless curr_action == 'restart_after_certs'
    when 'restart_after_certs'
      redirect_to controller: 'sa_setup', action: 'system_verification' unless curr_action == 'system_verification'
    when 'system_verification'
      redirect_to controller: 'sa_setup', action: 'log_files_location' unless curr_action == 'log_files_location'
    when 'log_files_location'
      redirect_to controller: 'sa_setup', action: 'log_files_location_verification' unless curr_action == 'log_files_location_verification'
    when 'log_files_location_verification'
      redirect_to controller: 'sa_setup', action: 'gpg_passphrase' unless curr_action == 'gpg_passphrase'
    when 'gpg_passphrase'
      redirect_to root_path
    else
      raise "Illegal setup_state: #{setup_state}"
    end

  end
end
