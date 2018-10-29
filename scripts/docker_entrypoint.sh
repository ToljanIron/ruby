#!/bin/sh

######################################################
# This script is where we place code that will run
# when the docker starts running, but before it starts
# nginx.
######################################################

# For some reason the ssh daemon is down so we restart it
sudo service ssh restart

# Need to make sure tmp/cache and tmp/data are there with
#  correct permissions
mkdir /home/app/sa/tmp
mkdir /home/app/sa/tmp/cache
mkdir /home/app/sa/tmp/data
chown -R app:app /home/app/sa/tmp
chmod -R 755 /home/app/sa/tmp


exec $@
