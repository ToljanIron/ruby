#!/bin/bash -l

echo "Dropping old db"
rake db:drop
echo "Creating db"
rake db:create
echo "Run migrations"
rake db:migrate
echo "Run seed"
rake db:seed:onprem_company_seed
