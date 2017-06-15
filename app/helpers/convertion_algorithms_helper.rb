# this module should hold task creation methods
module ConvertionAlgorithmsHelper
  # use for manual testing
  def monthly_email_collection_from_spectory(jobs_queue_id)
    machine_id = ApiClient.find_by(client_name: 'spectory_collector').id
    monthly_email_collection_from_exchange_machine_by_days(jobs_queue_id, machine_id)
  end

  def monthly_email_collection_from_icl(jobs_queue_id)
    icl_machine_id = ApiClient.find_by(client_name: 'icl exhange').id
    monthly_email_collection_from_exchange_machine_by_days(jobs_queue_id, icl_machine_id)
  end

  def test_company_google_create_monitors(jobs_queue_id, d_id = nil)
    jq = JobsQueue.find(jobs_queue_id)
    c = jq.try(:job).try(:company)
    fail 'test_company_google_create_monitors: invalid company' unless c
    t_id = ApiClientTaskDefinition.find_by(name: 'google monitor creator').id
    d_id = Domain.where(company_id: c.id).pluck(:id).first unless d_id
    refresh_token = EmailService.where(domain_id: d_id, name: 'gmail').first[:refresh_token]
    params = {
      users: c.monitored_user_names,
      client_secret: ENV['google_client_secret'],
      client_id: ENV['google_client_id'],
      refresh_token: refresh_token
    }.to_json
    ScheduledApiClientTask.create_scheduled_task(t_id, jobs_queue_id, params)
  end

  def daily_emails_collection_from_google_test_company(jobs_queue_id, d_id = nil)
    jq = JobsQueue.find(jobs_queue_id)
    c = jq.try(:job).try(:company)
    fail 'daily_emails_collection_from_google_test_company: invalid company' unless c
    t_id = ApiClientTaskDefinition.find_by(name: 'google emails collector').id
    sender_task_id = ApiClientTaskDefinition.find_by(name: 'sender').id
    d_id = Domain.where(company_id: c.id).pluck(:id) if d_id.nil?
    refresh_token = EmailService.where(domain_id: d_id, name: 'gmail').first[:refresh_token]
    params = {
      user_email: 'reports@2testahead.com',
      from: '', # TODO: get time param from db
      to: '', # TODO: get time param from db
      company_name: c.name,
      client_secret: ENV['google_client_secret'],
      client_id: ENV['google_client_id'],
      refresh_token: refresh_token
    }.to_json
    ScheduledApiClientTask.create_scheduled_task(t_id, jobs_queue_id, params)
    ScheduledApiClientTask.create_scheduled_task(sender_task_id, jobs_queue_id, params)
  end

  def daily_emails_collection_from_exchange_test_company(jobs_queue_id)
    jq = JobsQueue.find(jobs_queue_id)
    c = jq.try(:job).try(:company)
    fail 'daily_emails_collection_from_exchange_test_company: invalid company' unless c
    t_id = ApiClientTaskDefinition.find_by(name: 'exchange emails collector').id
    sender_task_id = ApiClientTaskDefinition.find_by(name: 'sender').id
    params = {
      from_time: (Time.zone.now - 1.day).strftime('%m/%d/%Y %H:%M:%S'),
      to_time: Time.zone.now.strftime('%m/%d/%Y %H:%M:%S'),
      company_name: c.name
    }.to_json
    ScheduledApiClientTask.create_scheduled_task(t_id, jobs_queue_id, params)
    ScheduledApiClientTask.create_scheduled_task(sender_task_id, jobs_queue_id, params)
  end

  def daily_emails_collection_from_exchange_e2e_test(jobs_queue_id)
    jq = JobsQueue.find(jobs_queue_id)
    c = jq.try(:job).try(:company)
    fail 'daily_emails_collection_from_exchange_e2e_test: invalid company' unless c
    t_id = ApiClientTaskDefinition.find_by(name: 'exchange emails collector').id
    sender_task_id = ApiClientTaskDefinition.find_by(name: 'sender').id
    from_days = (60 - Time.now.strftime('%M').to_i)
    to_days   = from_days - 7
    params = {
      from_time: from_days.day.ago.strftime('%m/%d/%Y %H:%M:%S'),
      to_time:   to_days.day.ago.strftime('%m/%d/%Y %H:%M:%S'),
      company_name: c.name
    }.to_json
    ScheduledApiClientTask.create_scheduled_task(t_id, jobs_queue_id, params)
    ScheduledApiClientTask.create_scheduled_task(sender_task_id, jobs_queue_id, params)
  end

  def recovery_emails_collection(jobs_queue_id, start_time, end_time, company_name, task_name)
    api_id = ApiClient.find_by(client_name: company_name).id
    sender_task_id = ApiClientTaskDefinition.find_by(name: 'sender').id
    collector_task_id = ApiClientTaskDefinition.find_by(name: task_name).id
    args = {
      jobs_queue_id: jobs_queue_id,
      api_client_id: api_id,
      tasks_ids: [collector_task_id, sender_task_id],
      from_time: start_time,
      to_time: end_time,
      delta_time: 1.day
    }
    interlace_tasks_with_time_delta_as_params(args)
  end

  private

  def monthly_email_collection_from_exchange_machine_by_days(jobs_queue_id, api_client_id)
    collector_task_id = ApiClientTaskDefinition.find_by(name: 'exchange email collector').id
    sender_task_id = ApiClientTaskDefinition.find_by(name: 'sender').id
    args = {
      jobs_queue_id: jobs_queue_id,
      api_client_id: api_client_id,
      tasks_ids: [collector_task_id, sender_task_id],
      from_time: Time.zone.now - 7.days,
      to_time: Time.zone.now,
      delta_time: 1.day
    }
    interlace_tasks_with_time_delta_as_params args
  end

  def interlace_tasks_with_time_delta_as_params(args)
    from_time = args[:from_time]
    to_time = args[:to_time]
    delta_time = args[:delta_time]
    while from_time < to_time
      params = {}
      params[:from_time] = from_time.strftime('%m/%d/%Y %H:%M:%S')
      from_time += delta_time
      params[:to_time] = [from_time, to_time].min.strftime('%m/%d/%Y %H:%M:%S')
      params = params.to_json
      args[:tasks_ids].each do |t_id|
        ScheduledApiClientTask.create_scheduled_task(t_id, args[:jobs_queue_id], params, args[:api_client_id])
      end
    end
  end
end
