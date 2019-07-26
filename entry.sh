#!/usr/bin/env bash

########################
###   docker entry   ###
########################

# set -e: if any command exit with a non zero value, won't execute the next command
# set -x: print the next executed command
set -e

# init hosts and ports of tracker server and fdht server
#
# the default value defined in Dockerfile is:
#
# ENV STORAGE_PORT=23000
# ENV STORAGE_HTTP_PORT=8888
# ENV TRACKER_PORT=22122
# ENV TRACKER_HTTP_PORT=8080
# ENV FDHT_PORT=11411
# ENV FDFS_CONF_DIR=/etc/fdfs
# ENV FDHT_CONF_DIR=/etc/fdht
#
# environment variables from "docker run -e" :
#
# TRACKER_HOST
# STORAGE_HOST


# get runtime ip as default host
IP=`ifconfig eth0 | grep inet | awk '{print $2}'`

if [[ -z "$TRACKER_HOST" ]]; then
  TRACKER_HOST="$IP"
fi
if [[ -z "$STORAGE_HOST" ]]; then
  STORAGE_HOST="$IP"
fi
if [[ -z "$FDHT_HOST" ]]; then
  FDHT_HOST="$IP"
fi

# update conf files
sed -i "s|^tracker_server=.*$|tracker_server=$TRACKER_HOST:$TRACKER_PORT|g" ${FDFS_CONF_DIR}/client.conf
sed -i "s|^tracker_server=.*$|tracker_server=$TRACKER_HOST:$TRACKER_PORT|g" ${FDFS_CONF_DIR}/storage.conf
sed -i "s|^tracker_server=.*$|tracker_server=$TRACKER_HOST:$TRACKER_PORT|g" ${FDFS_CONF_DIR}/mod_fastdfs.conf
sed -i "s|^group0.*$|group0=$FDHT_HOST:$FDHT_PORT|g"                        ${FDHT_CONF_DIR}/fdht_servers.conf

if [[ -z $1 ]]; then
  fdfs tracker
  fdfs storage
  fdfs dht
  nginx
  tail -f /var/log/nginx/access.log

elif [[ $1 == "nginx" ]]; then
  nginx
  tail -f /var/log/nginx/access.log

elif [[ $1 == "storage" ]]; then
  fdfs storage
  nginx
  tail -f /var/log/nginx/access.log

elif [[ $1 == "tracker" ]]; then
  fdfs tracker
  tail -f /dev/null

elif [[ $1 == "dht" ]]; then
  fdfs dht
  tail -f /dev/null

else
  sh -c "$*"
fi
