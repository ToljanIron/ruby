#!/bin/bash

#run db container, expose 55432 for pgadmin access
DBC=$(docker run -d -e POSTGRES_USER=workships -e POSTGRES_PASSWORD=workships -p 55432:5432 postgres)

# build images app. database.yml should state postgress as the user, no password.
docker build -t spectory/workships .

# run the app, in development env, expose port 3000, link with DBC as postgres alias
APPC=$(docker run -e PASSENGER_APP_ENV=development -e POSTGRES_USER=workships -e POSTGRES_PASSWORD=workships -p 3000:80 --link $DBC:postgres -d spectory/workships)

# or run while mounthing app folder for debug
# APPC=$(docker run -e PASSENGER_APP_ENV=development -v `pwd`/app:/home/app/webapp/app -p 5000:80 --link $DBC:postgres -d spectory/workships)

# show log
docker logs -f $APPC