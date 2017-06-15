#!/bin/bash

bundle install
rake db:migrate
rake db:seed:onprem_company_seed
rake db:seed:event_types
rake db:seed:metrics
rake db:seed:colors
rake assets:precompile
nginxup=`ps -ef | grep nginx | grep master | wc -l`
if [ $nginxup -ne 0 ]
then
  sudo service nginx restart
else
  sudo service nginx start
fi

