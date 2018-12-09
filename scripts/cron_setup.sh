#!/bin/bash -l

echo "Setting Cron"

export RAILS_ENV=onpremise
job=`cat /etc/crontab | grep delayed_jobs_scheduler`
if [ "$job" = "" ];then
  cmd="RAILS_ENV=$RAILS_ENV rake db:delayed_jobs_scheduler"
  echo "* * * * * root $cmd" >> /etc/crontab
fi

echo "Done ..."
