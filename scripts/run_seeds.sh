#!/bin/bash

echo "Type admin user password"
#read password
#export ADMIN_USER_PASSWORD=$password
export ADMIN_USER_PASSWORD=12345

echo "Type company_name"
#read company_name
#export COMPANY_NAME=$company_name
export COMPANY_NAME=Questcomp

echo "Type company_domain"
#read company_domain
#export COMPANY_DOMAIN=$company_domain
export COMPANY_DOMAIN=questcomp.com

echo "Drop DB"
RAILS_ENV=onpremise rake db:drop

echo "Create DB"
RAILS_ENV=onpremise rake db:create

echo "Run migrations"
RAILS_ENV=onpremise rake db:migrate

echo "Run seeds"
echo "======================="
RAILS_ENV=onpremise rake db:seed:company db:seed:admin_user db:seed:algorithm_types db:seed:algorithms db:seed:colors db:seed:event_types db:seed:languages db:seed:ranks db:seed:configuration db:seed:age_group_and_seniority db:seed:marital_statuses db:seed:network_names

echo
echo "Create company metrics"
RAILS_ENV=onpremise rake db:create_company_metrics_seed_to_cds\[1\]

echo "Done"
