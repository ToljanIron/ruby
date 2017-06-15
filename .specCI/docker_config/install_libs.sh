#!/bin/bash
sudo apt-get update
sudo apt-get install -yq libgtk2.0-dev libgtkmm* libnotify4
sudo npm install -g karma karma-cli karma-jasmine karma-coverage karma-phantomjs-launcher jslint