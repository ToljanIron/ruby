#!/usr/bin/zsh -l

rvm use 2.4.1

echo "Configuration"
rake db:seed:configuration

echo "algorithms"
rake db:seed:algorithms

echo "algorithm_types"
rake db:seed:algorithm_types

echo "colors"
rake db:seed:colors

echo "event_types"
rake db:seed:event_types

echo "languages"
rake db:seed:languages

echo "marital_atatuses"
rake db:seed:marital_statuses

echo "ranks"
rake db:seed:ranks

echo "Company"
rake db:seed:company
