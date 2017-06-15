require File.expand_path('../../config/boot',        __FILE__)
require File.expand_path('../../config/environment', __FILE__)
require 'clockwork'

include Clockwork

every(5.minutes, 'update jobs to jobs queue') do
  `rake db:update_jobs_to_jobs_queue`
end

every(1.minutes, 'run local job from jobs queue') do
  `rake db:run_local_job_from_jobs_queue`
end

every(10.minutes, 'run monitor and update the job queue') do
  `rake db:run_monitor_and_update_the_job_queue`
end

every(1.day, 'Precalculate', :at => '00:01') do
  `rake db:precalculate_metric_scores_for_custom_data_system\[-1,-1,-1,-1,-1,true\]`
end
