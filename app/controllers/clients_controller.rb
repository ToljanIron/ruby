include CdsUtilHelper

class ClientsController < ApiController
  # render job number(according to lib/jobs_protocol.yaml) and cerdantials/arguments needed by client script.
  def next_task
    token = request.headers['token']
    c_id = ApiClient.find_by(token: token).try(:id)
    next_task = ScheduledApiClientTask.next_task c_id
    if next_task
      res = {
        task_id: next_task.id,
        params: next_task.try(:params),
        script_path: next_task.api_client_task_definition.script_path
      }
    else
      res = { nothing_to_do: 'nothing to do' }
    end
    render json: res, status: 200
  end

  # report back when jobs has finished, and specify in which status(succ, error).
  def task_done
    token = request.headers['token']
    body = request.body.read
    body = JSON.parse body
    task_id =  body['task_id']
    task_status = body['task_status']
    c_id = ApiClient.find_by(token: token).try(:id)
    task = ScheduledApiClientTask.find(task_id)
    fail "task_done: task was assigned ApiClient #{task.api_client_id}, but ApiClient #{c_id} reported back" if c_id != task.api_client_id
    fail 'task_done: no such task' unless task
    task.change_status_to_done
    if task.api_client_task_definition.name == 'sender'
      task.jobs_queue.update_attribute(:status, JobsQueue::ENDED)
    end
    render json: 'ok', status: 200
  rescue => _e
    puts _e.message
    puts _e.backtrace.join("\n")
    render json: 'failed', status: 500
  end

  def sync_config
    token = request.headers['token']
    api_client = ApiClient.find_by(token: token)
    body = request.body.read
    body = JSON.parse body
    serial =  body['serial']
    fail unless serial
    if api_client.needs_config_sync? serial
      api_client.update_config body
      render json: { msg: 'config file was updated!' }, status: 202
    else
      render json: { msg: 'config file is up to date' }, status: 200
    end
  rescue => _e
    render json: { msg: 'failed to check config file status' }, status: 499
  end

  def upload_log
    token = request.headers['token']
    api_client = ApiClient.find_by(token: token)
    body = request.body.read
    body = JSON.parse body
    log = Base64.decode64(body['file'])
    file = Tempfile.new(['log-', api_client.client_name, '-'].join + '.zip')
    file.write log
    file.rewind
    CdsUtilHelper.upload_to_s3 file.path
    file.close
    file.unlink
    render json: { msg: 'log was uploaded' }, status: 200
  rescue
    file.close
    file.unlink
    render json: { msg: 'failed to upload' }, status: 500
  end

  def request_google_access
    base_url = 'https://accounts.google.com/o/oauth2/auth?'
    audit_scope = 'https://apps-apis.google.com/a/feeds/compliance/audit/'
    domain_id = params[:domain_id]

    scopes = "scope=#{audit_scope}"
    state = "state=#{domain_id}"
    redirect_uri = "redirect_uri=#{accept_google_access_url}"
    response_type = 'response_type=code'
    client_id = "client_id=#{ENV['google_client_id']}"
    access_type = 'access_type=offline'
    force = 'approval_prompt=force'

    url = [
      base_url + scopes,
      state,
      redirect_uri,
      response_type,
      client_id,
      access_type,
      force
    ].join('&')
    redirect_to url
    # https://accounts.google.com/o/oauth2/auth?scope=https://apps-apis.google.com/a/feeds/compliance/audit/&state=1&redirect_uri=http://localhost:3000/accept_google_access&response_type=code&client_id=184820652380-khbb66fvaurfphf3ea7t7nkt54udugml.apps.googleusercontent.com&access_type=offline&approval_prompt=force
  end

  def accept_google_access
    domain_id = params[:state]
    domain = Domain.find(domain_id)
    fail "accept_google_access: '#{domain_id}' is invalid domain_id" unless domain
    email_service = EmailService.where(domain_id: domain_id).first
    fail 'accept_google_access: email_service not found for this domain' if email_service.nil?
    fail "accept_google_access: get error #{params[:error]}" if params[:error]
    res = covert_code_to_tokens(params[:code], accept_google_access_url)
    refresh_token = res['refresh_token']
    email_service.update(refresh_token: refresh_token)
    company_domains = Domain.where(company_id: current_user.company_id)
    if EmailService.where(domain_id: company_domains.to_a, name: 'gmail', refresh_token: nil).any?
      redirect_to domains_list_path
    else
      redirect_to root_path
    end
  rescue => _e
    redirect_to signout_path, alert: 'Failed to get google access!'
  end

  def export_to_csv
    body = request.body.read
    json = JSON.parse body
    company_id = json['company_id']
    comp = Company.find(company_id)
    res = comp.export_to_csv
    render json: { emails: res }, status: 200
  end

  def collect_error_lines
    body = request.body.read
    params = JSON.parse(JSON.parse(body))
    params.each do |hash|
      type = hash['type']
      msg = hash['msg']
      EventLog.log_event(event_type_name: type, message: msg)
    end
      render json: { status: 200 }, status: 200
  end

  private

  def covert_code_to_tokens(code, redirect_uri)
    convert_code_to_tokens_url = 'https://www.googleapis.com/oauth2/v3/token'
    body = [
      "code=#{code}",
      "client_id=#{ENV['google_client_id']}",
      "client_secret=#{ENV['google_client_secret']}",
      "redirect_uri=#{redirect_uri}",
      'grant_type=authorization_code'
    ].join('&')
    response = CdsUtilHelper.run_syncronic_post(convert_code_to_tokens_url, body)
    return JSON.parse response
  end
end
