# fdfs-docker
Docker Image of FastDFS, include FastDHTDFS and fastdfs-nginx-module

## build image

On the host:

~~~bash
$ docker build -t fdfs .
~~~

## start a container

get into the container bash:

~~~bash
$ docker run -it --rm fdfs bash
~~~

just run the container, not get into the container bash:

~~~bash
$ docker run -d --rm fdfs
~~~

## files locations

| item             | location        |
| ---------------- | --------------- |
| nginx bin        | /usr/sbin/nginx |
| nginx conf       | /etc/nginx      |
| nginx log        | /var/log/nginx  |
| FastDFS bin dir  | /usr/bin        |
| FastDFS conf dir | /etc/fdfs       |
| FastDFS data dir | /var/local/fdfs |
| FastDHT bin dir  | /usr/local/bin  |
| FastDHT conf dir | /etc/fdht       |
| FastDHT data dir | /var/local/fdht |
|                  |                 |

FastDFS commands:
~~~bash
root@c32b79a9c9f0:/usr/bin# ls fdfs*
fdfs                fdfs_appender_test1  fdfs_download_file  fdfs_storaged  
fdfs_trackerd       fdfs_append_file     fdfs_crc32          fdfs_file_info
fdfs_test           fdfs_upload_appender fdfs_appender_test  fdfs_delete_file     fdfs_monitor        fdfs_test1           fdfs_upload_file
~~~
FastDHT commands:
~~~bash
root@c32b79a9c9f0:/usr/local/bin# ls fdht*
fdht_batch_test  fdht_delete  fdht_set   fdht_test_get  fdht_test_thread
fdht_compress    fdht_get     fdht_test  fdht_test_set  fdhtd
~~~

## script for running

There is a shell script location in `/usr/bin/fdfs`，with it you can easily run FastDFS or FastDHT

~~~bash
root@c32b79a9c9f0:~# fdfs 
============== HELP ===================
====Start all: FastDFS storage, FastDFS tracker, FastDHT, Nginx
0.start all           -->  fdfs all

====FastDFS: 
0. storage start      -->  fdfs storage start, or: fdfs storage
1. storage stop       -->  fdfs storage stop
2. storage restart    -->  fdfs storage restart
3. tracker start      -->  fdfs tracker start, or: fdfs tracker
4. tracker stop       -->  fdfs tracker stop
5. tracker restart    -->  fdfs tracker restart
6. test upload file   -->  fdfs test upload

====FastDHT: 
0. start              -->  fdfs dht start, or: fdfs dht
1. stop upload file   -->  fdfs dht stop
2. restart            -->  fdfs dht restart
3. test upload file   -->  fdfs test dht
=======================================
~~~



## run and test

~~~bash
# create data volumes directories (on host machine)
$ mkdir -p ~/data/fdfs/store0 ~/data/fdht

# run and mount data volumes (on host machine)
$ docker run -it --rm --name fdfs -p 80:80 \
             -v ~/data/fdfs:/var/local/fdfs \ 
             -v ~/data/fdht:/var/local/fdht \
             fdfs bash

# start FastDFS storage, FastDFS tracker, FastDHT, Nginx
$ fdfs all

# test upload
$ fdfs test upload
~~~

you can see the uploaded file in the container's directoy:
    `/var/local/fdfs/store0/data/00/00`

or in the host's directoy:
    `~/data/fdfs/store0/data/00/00`

if you do "fdfs test upload" multi times, it will upload the same file multi times, but # each new uploaded file just create a link to the already existed file