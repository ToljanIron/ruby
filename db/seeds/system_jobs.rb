
start_and_fail_every_12_hours = Reoccurrence.find_by(name: '12_12') || Reoccurrence.create(run_every_by_minutes: 720, fail_after_by_minutes: 720, name: '12_12')
start_and_fail_every_hour = Reoccurrence.find_by(name: '1h') || Reoccurrence.create(run_every_by_minutes: 60, fail_after_by_minutes: 60, name: '1h')
start_and_fail_every_10_minutes = Reoccurrence.find_by(name: '10m') || Reoccurrence.create(run_every_by_minutes: 10, fail_after_by_minutes: 10, name: '10m')

# Those Jobs run by heroku scheduler (or by cron job in case of on premise installtion)
# Since they are not triggered by JobsQueue, you cannot set dependencies between them.

Job.create_new_job('db:update_images_from_s3', nil, start_and_fail_every_12_hours, Job::SYSTEM_JOB) # TODO run this job only on heroku.

Job.create_new_job('db:create_scheduled_tasks', nil, start_and_fail_every_10_minutes, Job::SYSTEM_JOB)
Job.create_new_job('db:archive_scheduled_tasks', nil, start_and_fail_every_10_minutes, Job::SYSTEM_JOB)
Job.create_new_job('db:mark_errors_on_scheduled_tasks', nil, start_and_fail_every_10_minutes, Job::SYSTEM_JOB)
Job.create_new_job('db:keep_alive_task', nil, start_and_fail_every_10_minutes, Job::SYSTEM_JOB)
Job.create_new_job('db:invalid_state_error_tasks', nil, start_and_fail_every_12_hours, Job::SYSTEM_JOB)

# Example to job:
#  r  = Reoccurrence.create(run_every_by_minutes: 2, fail_after_by_minutes: 2, name: '2_2')
# Job.create_new_job('db:create_and_calculate_presets', nil, r , Job::SYSTEM_JOB, "[2]")

# run at heroku
# db:schedule_system_jobs_task
# db:schedule_jobs
