require 'oj'
require 'oj_mimic_json'

include ImportDataHelper

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

    CompanyConfigurationTable.find_by(
      key: 'APP_SERVER_NAME',
      comp_id: -1
    ).update(value: server_name)
    Company.last.update(setup_state: :server_name)
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

    Company.last.update(setup_state: :datetime)
    redirect_to controller: 'sa_setup', action: 'base'
  end

  def certs
    redirect_if_needed
    puts "In certs"
  end

  def certs_set
    puts "in certs_set"
    params.permit(:certFile, :keyFile)


    ########################################################################################
    # Work on the CRT file
    ########################################################################################

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

    ########################################################################################
    # Work on the KEY file
    ########################################################################################

    # Save file to /tmp
    key_file = params[:keyFile][:file]
    file_name = key_file.original_filename
    path = File.join("/tmp", file_name)
    File.open(path, "wb") { |f| f.write(key_file.read) }

    # Verify file
    is_valid = `openssl rsa -in #{path} -check 2> /dev/null; echo $?;`.to_i === 0
    if !is_valid
      redirect_to_error("Key file is invalid: #{file_name}")
      return
    end

    ########################################################################################
    # This script will do the following:
    #   1. Move the crt file to its promer location
    #   2. Change ownership to root
    #   3. Set permissions on it
    #   4. Repeat 1,2,3 on the key file
    #   5. Set the correct certificate name and location in ssl-params.conf
    #   6. Update sites-enabled to a SSL site
    #   7. Set config.force_ssl to "true" in the environemt file
    ########################################################################################
    if Rails.env.production? || Rails.env.onpremise?
      `nohup sudo /home/app/sa/scripts/ssl_setup.sh onpremise >> /home/app/sa/log/onpremise.log 2>&1 &`
    else
      `nohup sudo /home/app/sa/scripts/ssl_setup.sh onpremise >> /home/app/sa/log/development.log 2>&1 &`
    end

    Company.last.update(setup_state: :certs)
    redirect_to controller: 'sa_setup', action: 'base'
  end

  def log_files_location
    redirect_if_needed
    puts "in log_files_location"
  end

  def log_files_location_set
    puts "in log_files_location_set"
    params.permit(:sftpHost, :sftpUser, :sftpPassword, :sftpLogsDir)

    host = params[:sftpHost].sanitize_url
    if host.nil?
      redirect_to_error("Bad value for host name: #{params[:sftpHost]}")
      return
    end

    user = params[:sftpUser].sanitize_is_alphanumeric
    if user.nil?
      redirect_to_error("Bad value for username: #{params[:sftpUser]}")
      return
    end

    pass = params[:sftpPassword].sanitize_is_alphanumeric
    if pass.nil?
      redirect_to_error("Bad value for password: #{params[:sftpPassword]}")
      return
    end

    logs_dir = params[:sftpLogsDir].sanitize_is_alphanumeric
    if pass.nil?
      redirect_to_error("Bad value for log files directory: #{params[:sftpLogsDir]}")
      return
    end

    CompanyConfigurationTable.find_by(
      key: 'COLLECTOR_TRNAS_TYPE',
      comp_id: -1
    ).update(value: 'SFTP')
    CompanyConfigurationTable.find_by(
      key: 'COLLECTOR_TRNAS_HOST',
      comp_id: -1
    ).update(value: host)
    CompanyConfigurationTable.find_by(
      key: 'COLLECTOR_TRNAS_USER',
      comp_id: -1
    ).update(value: user)
    CompanyConfigurationTable.find_by(
      key: 'COLLECTOR_TRNAS_PASSWORD',
      comp_id: -1
    ).update(value: CdsUtilHelper.encrypt(pass))
    CompanyConfigurationTable.find_by(
      key: 'COLLECTOR_TRNAS_SRC_DIR',
      comp_id: -1
    ).update(value: logs_dir)

    Company.last.update(setup_state: :log_files_location)
    redirect_to controller: 'sa_setup', action: 'base'
  end

  def log_files_location_verification
    puts "in log_files_location_verification"
    Company.last.update(setup_state: :gpg_passphrase)
    redirect_to controller: 'sa_setup', action: 'base'
  end

  def gpg_passphrase
    redirect_if_needed
    puts "in gpg_passphrase"
  end

  def gpg_passphrase_set
    puts "in gpg_passphrase"
    params.permit(:gpgPassphrase)

    gpgpass = params[:gpgPassphrase].sanitize_is_alphanumeric
    if gpgpass.nil?
      redirect_to_error("Bad GPG passphrase: #{params[:gpgPassphrase]}")
      return
    end

    CompanyConfigurationTable.find_by(
      key: 'COLLECTOR_DECRYPTION_PASSPHRASE',
      comp_id: -1
    ).update( value: CdsUtilHelper.encrypt(gpgpass) )
    Company.last.update(setup_state: :it_done)

    if Rails.env.production? || Rails.env.onpremise?
      `nohup sudo /home/app/sa/scripts/cron_setup.sh >> /home/app/sa/log/onpremise.log 2>&1 &`
    else
      `nohup sudo /home/app/sa/scripts/icron_setup.sh >> /home/app/sa/log/development.log 2>&1 &`
    end

    redirect_to controller: 'sa_setup', action: 'base'
  end

  def it_done
    puts "in it_done"
  end

  def upload_company
    puts "in upload_company"
    if Employee.count > 0
      Company.last.update(setup_state: :standby_or_push)
      redirect_to controller: 'sa_setup', action: 'base'
    end
    Company.last.update(setup_state: :upload_company)
  end

  def employees_excel
    puts "Uploading employees_excel"
    params.permit(:empsExcel)
    emps_file = params[:empsExcel][:file]

    _, errors = load_excel_sheet(1, emps_file, 1, true)
    if !errors.nil? && errors.count > 0
      redirect_to_error("Upload errors: #{errors}")
      return
    end

    Company.last.update(setup_state: :standby_or_push)
    redirect_to controller: 'sa_setup', action: 'base'
  end

  def standby_or_push
    puts "in standby_or_push"
  end

  def goto_system
    puts "in goto_system"
    Company.last.update(setup_state: :ready)
    render plain: "Done"
  end

  def collect_now
    puts "in collect_now"
    Company.last.update(setup_state: :push)
    PushProc.create(company_id: Company.last.id)
    Delayed::Job.enqueue(
      HistoricalDataJob.new,
      queue: 'collector_queue',
      run_at: 5.hours.ago
    )
    redirect_to controller: 'sa_setup', action: 'base'
  end

  def push
    puts "in push"
  end

  def get_push_state
    puts "In get_push_state"
    pp = Company.last.push_proc
    render json: Oj.dump( pp ), status: 200

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
      redirect_to controller: 'sa_setup', action: 'log_files_location' unless curr_action == 'log_files_location'
    when 'log_files_location'
      #redirect_to controller: 'sa_setup', action: 'log_files_location_verification' unless curr_action == 'log_files_location_verification'
      redirect_to controller: 'sa_setup', action: 'gpg_passphrase' unless curr_action == 'gpg_passphrase'
    when 'log_files_location_verification'
      redirect_to controller: 'sa_setup', action: 'gpg_passphrase' unless curr_action == 'gpg_passphrase'
    when 'gpg_passphrase'
      redirect_to controller: 'sa_setup', action: 'it_done' unless curr_action == 'it_done'
    when 'it_done'
      redirect_to controller: 'sa_setup', action: 'it_done' unless curr_action == 'it_done'
    when 'upload_company'
      redirect_to controller: 'sa_setup', action: 'upload_company' unless curr_action == 'upload_company'
    when 'standby_or_push'
      redirect_to controller: 'sa_setup', action: 'standby_or_push' unless curr_action == 'standby_or_push'
    when 'goto_system'
      redirect_to controller: 'sa_setup', action: 'goto_system' unless curr_action == 'goto_system'
    when 'collect_now'
      redirect_to controller: 'sa_setup', action: 'collect_now' unless curr_action == 'collect_now'
    when 'push'
      redirect_to controller: 'sa_setup', action: 'push' unless curr_action == 'push'
    else
      raise "Illegal setup_state: #{setup_state}"
    end
  end
end
