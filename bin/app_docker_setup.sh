#!/bin/bash -l

###########################################################
# This file is used by Docker.app for container setup
###########################################################
cd /home/app/sa

## nginx setup
cp templates/step-ahead.com.crt /etc/ssl/certs/step-ahead.com.crt
cp templates/step-ahead.com.key /etc/ssl/private/step-ahead.com.key
cp templates/sa-nginx.conf.ssltemplate /etc/nginx/sites-available/sa-nginx.conf.ssltemplate
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/sa-nginx.conf.ssltemplate /etc/nginx/sites-enabled/step-ahead.com.conf
cp templates/ssl-params.conf.template /etc/nginx/snippets/ssl-params.conf

# This file tells ngnix which env vars to retain. The rest are deleted.
cp templates/env-vars.conf /etc/nginx/main.d/env-vars.conf

# Add some special permissions
cp templates/app-user-permissions /etc/sudoers.d/app-user-permissions

# Handle SSH
cp templates/authorized_keys_app /root/.ssh/authorized_keys
cp templates/ssh_config /etc/ssh/ssh_config
cp templates/sshd_config /etc/ssh/sshd_config

# Select ruby
rvm --default use ruby-2.4.4

# The container will run docker_entrypoint.sh before it starts running
mkdir -p /etc/my_init.d
cp scripts/docker_entrypoint.sh /etc/my_init.d

# Put the logrotate configuration file in place
cp templates/sa.logrotate /etc/logrotate.d/sa.logrotate
