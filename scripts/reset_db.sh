#!/bin/bash
echo 'dropping old db'
rake environment db:drop
echo 'creating new db'
rake db:create
echo 'migrate development db'
rake db:migrate
echo 'migrate test db'
rake db:migrate test

if [[ $1 == 'seed' ]]
then
  echo 'seeding development db'
  rake db:seed
  rake db:seed:users
  rake db:seed:event_types
  rake db:seed:metrics
  rake db:seed:marital_statuses
  rake db:seed:colors
  rake db:seed:age_group_and_seniority
  rake db:seed:ranks
  rake db:seed:reoccurrences
  rake db:seed:api_clients_and_configs
  rake db:seed:system_jobs
fi
