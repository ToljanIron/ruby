#!/bin/bash
rake db:schedule_system_jobs_task
rake db:archive_old_jobs
rake db:locate_and_archive_stuck_jobs
rake db:schedule_jobs