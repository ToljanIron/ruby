#!/bin/bash

echo "Type admin user password"
read password
export ADMIN_USER_PASSWORD=$password

echo "Type company_name"
read company_name
export COMPANY_NAME=$company_name

echo "Type company_domain"
read company_domain
export COMPANY_DOMAIN=$company_domain


echo "Create company"
rake db:seed:company

echo "Create admin user"
rake db:seed:admin_user

echo "Create algorithm types"
rake db:seed:algorithm_types

echo "Create algorithms"
rake db:seed:algorithms

echo "Create colors"
rake db:seed:colors

echo "Create event_types"
rake db:seed:event_types

echo "Create languages"
rake db:seed:languages

echo "Create ranks"
rake db:seed:ranks

echo "Create company configurations"
rake db:seed:configuration

echo "Create age groups"
rake db:seed:age_group_and_seniority

echo "Create marital_statuses"
rake db:seed:marital_statuses

echo "Create network names"
rake db:seed:network_names

echo "Create company metrics"
rake db:create_company_metrics_seed_to_cds\[1\]
