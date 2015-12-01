#!/bin/bash

# Exit script as soon as first error is observed (see http://stackoverflow.com/a/1379904/2161065)
set -e

echo "--- Restoring of redmine backup  ---"

#
# Sanity checks for necessary environment vars
#
echo "--- Checking for necessary environment variables ---"
: "${BACKUP_NAME:?BACKUP_NAME needs to be defined!}"
: "${REDMINE_FILES:?REDMINE_FILES needs to be defined!}"
: "${S3_BUCKET_NAME:?S3_BUCKET_NAME needs to be defined!}"
: "${POSTGRES_PORT_5432_TCP_ADDR:?POSTGRES_PORT_5432_TCP_ADDR needs to be defined!}"
: "${POSTGRES_PORT_5432_TCP_PORT:?POSTGRES_PORT_5432_TCP_PORT needs to be defined!}"
: "${POSTGRES_ENV_DB_NAME:?POSTGRES_ENV_DB_NAME needs to be defined!}"
: "${POSTGRES_ENV_DB_USER:?POSTGRES_ENV_DB_USER needs to be defined!}"
: "${POSTGRES_ENV_DB_PASS:?POSTGRES_ENV_DB_PASS needs to be defined!}"

#
# Identify latest (and corresponding) backup files , and download them
#

echo "--- Identifying backup files to use ---"

# Find last backup file
: ${LAST_FILES_BACKUP:=$(aws s3 ls s3://$S3_BUCKET_NAME | awk -F " " '{print $4}' | grep ^$BACKUP_NAME-files- | sort -r | head -n1)}
echo "---   Found $LAST_FILES_BACKUP for files backup ---"
: ${LAST_POSTGRES_BACKUP:=$(aws s3 ls s3://$S3_BUCKET_NAME | awk -F " " '{print $4}' | grep ^$BACKUP_NAME-postgres- | sort -r | head -n1)}
echo "---   Found $LAST_POSTGRES_BACKUP for postgres backup ---"


# Check if backup files are corresponding in timestamp
# FIXME to be done

# Download files backup from S3
aws s3 cp s3://$S3_BUCKET_NAME/$LAST_FILES_BACKUP $LAST_FILES_BACKUP
aws s3 cp s3://$S3_BUCKET_NAME/$LAST_POSTGRES_BACKUP $LAST_POSTGRES_BACKUP
echo "---   Downloaded backup files from AWS S3 ---"

#
# Extract files backup
#
echo "--- Restoring files ---"

# Extract backup
#tar xvfpz $LAST_FILES_BACKUP 

#
# Extract postgres backup
#
echo "--- Restoring postgres schema and data ---"

# Create .pgpass file in home directory, and set it to 600 (see http://stackoverflow.com/questions/2893954/how-to-pass-in-password-to-pg-dump)
echo "${POSTGRES_PORT_5432_TCP_ADDR}:${POSTGRES_PORT_5432_TCP_PORT}:${POSTGRES_ENV_DB_NAME}:${POSTGRES_ENV_DB_USER}:${POSTGRES_ENV_DB_PASS}" > ~/.pgpass
chmod 600 ~/.pgpass
/usr/bin/pg_restore \
  -h $POSTGRES_PORT_5432_TCP_ADDR \
  -p $POSTGRES_PORT_5432_TCP_PORT \
  -d ${POSTGRES_ENV_DB_NAME} \
  -U ${POSTGRES_ENV_DB_USER} \
  --clean --if-exists --create \
  $LAST_POSTGRES_BACKUP
rm -rf ~/.pgpass

#
# Run any necessary scripts to bring stuff into proper shape
#

# I do not know anything to execute yet

echo "--- Restoring of redmine backup was sucessful! ---"
echo "--- Please restart your redmine and postgres container! ---"

