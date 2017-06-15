c = Company.create(name: 'spectory')
j = Job.create(
  company_id: c.id,
  next_run: Time.zone.now,
  name: 'spectory monthly email collection',
  reoccurrence: Reoccurrence.create_new_occurrence(Reoccurrence::HOUR_MINUTES, Reoccurrence::HOUR_MINUTES),
  type_number: Job::CLIENT_JOB
)

ApiClientTaskDefinition.create(
  name: 'exchange email collector',
  script_path: 'exchange/collect_emails_from_date_to_date.rb'
)
ApiClientTaskDefinition.create(
  name: 'sender',
  script_path: 'sender/sender.rb'
)
ApiClientTaskDefinition.create(
  name: 'update_config',
  script_path: './update_config.rb'
)

ApiClientTaskDefinition.create(
  name: 'upload_log',
  script_path: './upload_log.rb'
)

jtc = JobToApiClientTaskConvertor.create(
  job_id: j.id,
  algorithm_name: 'monthly_email_collection_from_spectory',
  name: 'monthly_email_collection_from_spectory'
)

j.update(job_to_api_client_task_convertor_id: jtc.id)

# ~~~~~~~~~~~~~~~~~~ google example start ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# create monitors
c = Company.create(name: 'spectory_google')
j = Job.create(
  company_id: c.id,
  next_run: Time.zone.now,
  name: 'spectory google monitor creation',
  reoccurrence: Reoccurrence.create_new_occurrence(Reoccurrence::MONTH_MINUTES, Reoccurrence::MONTH_MINUTES),
  type_number: Job::CLIENT_JOB
)
ApiClientTaskDefinition.create(
  name: 'google monitor creator',
  script_path: 'google/create_monitors.rb'
)
jtc = JobToApiClientTaskConvertor.create(
  job_id: j.id,
  algorithm_name: 'spectory_google_create_monitors',
  name: 'spectory_google_create_monitors'
)
j.update(job_to_api_client_task_convertor_id: jtc.id)

# collect_emails
j = Job.create(
  company_id: c.id,
  next_run: Time.zone.now,
  name: 'spectory daily email collection',
  reoccurrence: Reoccurrence.create_new_occurrence(Reoccurrence::DAY_MINUTES, Reoccurrence::DAY_MINUTES),
  type_number: Job::CLIENT_JOB
)

ApiClientTaskDefinition.create(
  name: 'google emails collector',
  script_path: 'google/collect_emails.rb'
)
jtc = JobToApiClientTaskConvertor.create(
  job_id: j.id,
  algorithm_name: 'daily_emails_collection_from_spectory',
  name: 'daily_emails_collection_from_spectory'
)
j.update(job_to_api_client_task_convertor_id: jtc.id)

# ~~~~~~~~~~~~~~~~~~ google example end ~~~~~~~~~~~~~~~~~~

# ./reset_db.sh && rake db:seed && rake db:seed:jobs_and_tasks && rake db:seed:employees_for_email_collector_test && rake db:seed:api_clients_and_configs
# rake db:schedule_jobs && rake db:create_scheduled_tasks

# rake db:create_snapshot\[1,"2015-03-30\ 11:27:11\ +0300",1\]
# rake db:precalculate_metric_scores\[1\]
