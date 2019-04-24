#!/bin/bash

echo "*****************************************"
echo "This seed is created in test mode. It means that some params"
echo "  are hardcoded:"
echo "  - admin password: 12345"
echo "  - company_name: Questcomp"
echo "  - domain: 2stepaheadtarget.onmicrosoft.com"
echo "to acknowladge click enter"
echo "*****************************************"
read anything

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
export COMPANY_DOMAIN=2stepaheadtarget.onmicrosoft.com

echo "Souring"
source /home/dev/Development/workships/.env

echo "Drop DB"
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 RAILS_ENV=onpremise rake db:drop

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
