FROM ubuntu:15.04
MAINTAINER Sascha Herrmann

RUN apt-get update 
RUN apt-get install -y python-pip && pip install awscli
RUN apt-get install -y postgresql-client
RUN apt-get clean -y

ADD backup.sh /backup.sh
ADD restore.sh /restore.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh

ENV S3_BUCKET_NAME docker-backups.example.com
ENV AWS_ACCESS_KEY_ID **DefineMe**
ENV AWS_SECRET_ACCESS_KEY **DefineMe**
ENV AWS_DEFAULT_REGION eu-central-1
# FIXME REDMINE_FILES should be taken from link to redmine container
ENV REDMINE_FILES /home/redmine/data
# ENV POSTGRES_ENV_DB_NAME **ToBeDefinedByLinkingToPostgresContainer**
# ENV POSTGRES_ENV_DB_USER **ToBeDefinedByLinkingToPostgresContainer**
# ENV POSTGRES_ENV_DB_PASS **ToBeDefinedByLinkingToPostgresContainer**
# ENV POSTGRES_PORT_5432_TCP_ADDR **ToBeDefinedByLinkingToPostgresContainer**
# ENV POSTGRES_PORT_5432_TCP_PORT **ToBeDefinedByLinkingToPostgresContainer**
ENV BACKUP_NAME backup-redmine
ENV RESTORE false

CMD ["/run.sh"]
