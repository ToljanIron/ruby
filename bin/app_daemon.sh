#!/bin/bash -l

###################################################################
#
# This daemon is in charge of running the schedualer and
# the delayed_job process.
#
# Schedualed jobs can be one of:
#   - Run an initial analyze job from historical data
#   - Create snapshot
#   - Precalculate
#
###################################################################
export APP_HOME=/home/app/sa
export RUN_ENV=$1

echo "SA app daemon wake up" >> /home/app/sa/log/onpremise.log
cd $APP_HOME

## Run schedualer
RAILS_ENV=$RUN_ENV rake db:delayed_jobs_scheduler

## Run delayed jobs
RAILS_ENV=$RUN_ENV QUEUE=app_queue rake jobs:workoff

## Run log rotate
