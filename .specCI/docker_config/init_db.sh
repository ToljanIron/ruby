#!/bin/bash
echo "creating new db"
rake db:create
echo "migrate development db"
rake db:migrate
echo "migrate test db"
rake db:migrate test
