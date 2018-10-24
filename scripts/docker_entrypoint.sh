#!/bin/sh

######################################################
# This script is where we place code that will run
# when the docker starts running, but before it starts
# nginx.
######################################################

# For some reason the ssh daemon is down so we restart it
sudo service ssh restart

exec $@
