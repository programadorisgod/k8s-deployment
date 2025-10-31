#!/bin/bash

set -e

DB_NAME=${DB_NAME_AUTH:-swyw_auth}
DB_ADMIN_PASSWORD=${DB_ADMIN_PASSWORD:-default}
DB_APP_USER_PASSWORD=${DB_APP_USER_PASSWORD:-default}


psql -U "$POSTGRES_USER" -tc "SELECT 1 FROM  pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
psql -U "$POSTGRES_USER" -c  "CREATE DATABASE $DB_NAME"



psql -U "$POSTGRES_USER" -tc "SELECT 1 FROM pg_roles WHERE rolname='db_admin'" | grep -q 1 || \
psql -U "$POSTGRES_USER" -c "CREATE ROLE db_admin LOGIN PASSWORD '$DB_ADMIN_PASSWORD' SUPERUSER;"

psql -U "$POSTGRES_USER" -tc "SELECT 1 FROM pg_roles WHERE rolname='app_user'" | grep -q 1 || \
psql -U "$POSTGRES_USER" -c "CREATE ROLE app_user LOGIN PASSWORD '$DB_APP_USER_PASSWORD';"

#connect to swyw_auth
psql -U "$POSTGRES_USER" -d $DB_NAME -c "CREATE SCHEMA IF NOT EXISTS core AUTHORIZATION app_user"
psql -U "$POSTGRES_USER" -d $DB_NAME -c "REVOKE ALL ON SCHEMA public FROM PUBLIC;"


#Privileges
psql -U "$POSTGRES_USER" -d $DB_NAME -c "GRANT USAGE, CREATE ON SCHEMA core TO app_user"
psql -U "$POSTGRES_USER" -d $DB_NAME -c "ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user"
psql -U "$POSTGRES_USER" -d $DB_NAME -c "ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT USAGE, SELECT ON SEQUENCES TO app_user"


#By 90% camidev + 10% AI
