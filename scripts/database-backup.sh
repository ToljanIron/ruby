#!/bin/bash -l

echo "Backing up database"
cd /home/sa/Production/workships/db
echo "  Removing old backups"
find . -name "seed*rb*gz" -type f -mtime +7 -exec rm {} \;
datestr=`date +%Y%m%d`
echo "Making backup"
rake RAILS_ENV=onpremise db:seed:dump EXCLUDE=created_at,updated_at
newname="seeds-backup-"$datestr".rb"
echo "Renaming"
mv seeds.rb $newname
echo "zipping"
gzip -9 $newname

echo "Database backup done ..."
