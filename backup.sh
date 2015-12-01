#!/bin/bash

# Exit script as soon as first error is observed (see http://stackoverflow.com/a/1379904/2161065)
set -e

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


# Get timestamp
echo "--- Generating timestamped filenames ---"
: ${BACKUP_SUFFIX:=$(date +"%Y-%m-%d-%H-%M-%S")}
readonly tarball=$BACKUP_NAME-files-$BACKUP_SUFFIX.tar.gz
readonly pgdump=$BACKUP_NAME-postgres-$BACKUP_SUFFIX.sqlc

#
# Redmine files backup
#
echo "--- Creating backup of redmine files ---"

# Create a gzip compressed tarball with the volume(s)
tar czf $tarball $BACKUP_TAR_OPTION $REDMINE_FILES

#
# Redmine postgres backup
#

echo "--- Creating backup of postgres database ---"
# Create .pgpass file in home directory, and set it to 600 (see http://stackoverflow.com/questions/2893954/how-to-pass-in-password-to-pg-dump)
echo "$POSTGRES_PORT_5432_TCP_ADDR:$POSTGRES_PORT_5432_TCP_PORT:${POSTGRES_ENV_DB_NAME}:${POSTGRES_ENV_DB_USER}:${POSTGRES_ENV_DB_PASS}" > ~/.pgpass
chmod 600 ~/.pgpass

# Create backup of database
/usr/bin/pg_dump \
  -h $POSTGRES_PORT_5432_TCP_ADDR \
  -p $POSTGRES_PORT_5432_TCP_PORT \
  -d $POSTGRES_ENV_DB_NAME \
  -U $POSTGRES_ENV_DB_USER \
  -Fc \
  --file=$pgdump
rm -rf ~/.pgpass

#
# Upload backup files to AWS S3
#
echo "--- Uploading backups to AWS S3 ---"

# Create bucket, if it doesn't already exist
BUCKET_EXIST=$(aws s3 ls | grep $S3_BUCKET_NAME | wc -l)
if [ $BUCKET_EXIST -eq 0 ];
then
  aws s3 mb s3://$S3_BUCKET_NAME
fi

# Upload the files backup to S3 with timestamp
aws s3 cp $tarball s3://$S3_BUCKET_NAME/$tarball

# Upload the psql backup to S3 with timestamp
aws s3 cp $pgdump s3://$S3_BUCKET_NAME/$pgdump

echo "--- Backup finished! ---"
