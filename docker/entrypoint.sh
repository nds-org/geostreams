#!/bin/bash

export POSTGRES_HOST=${POSTGRES_HOST:-localhost}
export POSTGRES_PORT=${POSTGRES_PORT:-5432}
export POSTGRES_USER=${POSTGRES_USER:-postgres}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-geostreams}
export POSTGRES_DB=${POSTGRES_DB:-geostreams}

export PGPASSWORD=${PGPASSWORD:-${POSTGRES_PASSWORD}}

# Delay startup
if [ "${*/--delay/FOUNDIT}" == "$*" ]; then
	echo Delaying startup to give PostGIS a bit more time to init...
	sleep 40s
	echo PostGIS initialized.
	touch ~/.postgisinit
fi


if [ "$POSTGIS_HOST" == "" ]; then
	export POSTGIS_HOST_ENV_KEY="${NDSLABS_STACK^^}_POSTGIS_SERVICE_HOST"                  
	export POSTGIS_HOST="${!POSTGIS_HOST}_ENV_KEY"
fi

# start right job
case $1 in
    "initialize" )
        echo "Creating new database schema..."
        psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -c "CREATE ROLE geostreams WITH LOGIN CREATEDB NOSUPERUSER NOCREATEROLE PASSWORD 'geostreams'"
        psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -c "CREATE DATABASE geostreams WITH OWNER geostreams"
        psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} geostreams < data/geostreams.sql
        ;;
    "deletedata" )
        echo "Dropping database, good luck."
        psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -c "DROP DATABASE geostreams;"
        ;;
    "initandserve" )
        echo "Creating new database schema..."
        psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -c "CREATE ROLE geostreams WITH LOGIN CREATEDB NOSUPERUSER NOCREATEROLE PASSWORD 'geostreams'"
        psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -c "CREATE DATABASE geostreams WITH OWNER geostreams"
        psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} geostreams < data/geostreams.sql
        echo "Starting service..."
        exec ./bin/geostreams.sh -Dconfig.file=/home/geostreams/conf/application.conf -Ddb.default.url="jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/?user=geostreams&password=geostreams"
        ;;
    "server" )
        echo "Starting service..."
        exec ./bin/geostreams.sh -Dconfig.file=/home/geostreams/conf/application.conf -Ddb.default.url="jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/?user=geostreams&password=geostreams"
        ;;
    "help" )
        echo "initialize   : create a new database and initialize with all data from server 0"
        echo "deletedata   : drop existing database"
        echo "server       : runs the geostreams API"
        echo "initandserve : runs 'initialize' then runs 'server'"
        echo "help         : this text"
        echo ""
        echo "Default is ??"
        ;;
    * )
        exec "$@"
        ;;
esac
