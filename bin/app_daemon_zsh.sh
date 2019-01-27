#!/bin/zsh -l

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

## Rails env
if [ "$1" eq '' ];then
  echo "First argument must be an envriornmt"
  exit 1
else
  export RUN_ENV=$1
fi

## home dir
if [ "$2" eq '' ];then
  export APP_HOME=/home/app/sa
else
  export APP_HOME=$2
fi

echo "SA app daemon wake up" >> $APP_HOME/log/onpremise.log
cd $APP_HOME

## Run schedualer
RAILS_ENV=$RUN_ENV rake db:delayed_jobs_scheduler

## Run delayed jobs
RAILS_ENV=$RUN_ENV QUEUE=app_queue rake jobs:workoff

## Run log rotate
