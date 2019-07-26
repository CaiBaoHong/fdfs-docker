# fdfs-docker
Docker Image of FastDFS, include FastDHT and fastdfs-nginx-module

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
root@c32b79a9c9f0:/usr/bin# ls fdfs
fdfs                fdfs_appender_test1  fdfs_download_file  fdfs_storaged  
fdfs_trackerd       fdfs_append_file     fdfs_crc32          fdfs_file_info
fdfs_test           fdfs_upload_appender fdfs_appender_test  fdfs_delete_file
fdfs_monitor        fdfs_test1           fdfs_upload_file
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
+----------------------------- HELP -----------------------------+
| start storage, tracker, nginx, fastdht  -->  $ fdfs all        |
|                                                                |
| FastDFS:                                                       |
|                                                                |
| storage start      -->  fdfs storage start, or: fdfs storage   |
| storage stop       -->  fdfs storage stop                      |
| storage restart    -->  fdfs storage restart                   |
| tracker start      -->  fdfs tracker start, or: fdfs tracker   |
| tracker stop       -->  fdfs tracker stop                      |
| tracker restart    -->  fdfs tracker restart                   |
| test upload file   -->  fdfs test upload                       |
|                                                                |
| FastDHT:                                                       |
|                                                                |
| start              -->  fdfs dht start, or: fdfs dht           |
| stop upload file   -->  fdfs dht stop                          |
| restart            -->  fdfs dht restart                       |
| test upload file   -->  fdfs test dht                          |
|                                                                |
+----------------------------------------------------------------+
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

## data manage

### mount data volume

recommend use [volume mount ](https://docs.docker.com/storage/volumes/) to run docker container:

~~~bash
$ docker run -it --rm -p 80:80 --name fdfs --mount type=volume,source=fdfs_data,target=/var/local fdfs bash
~~~

the option `--mount type=volume,source=fdfs_data,target=/var/local` means:

- these [three mount types](https://docs.docker.com/storage/) (volume, bind mounts, tmpfs mount), here we use **volume**
- auto create a named volume **"fdfs_data"** if not exists
- mount the container's  directory **"/var/local"** to the volume "fdfs_data"

when you are in the container's bash, do some upload test:

~~~bash
$ fdfs all
$ fdfs test upload
~~~

then you can find the uploaded files on your host directory: **/var/lib/docker/volumes/fdfs_data/_data**

### backup volume data

first, run a container, do not add option `--rm`:

~~~bash
$ docker run -it -p 80:80 --name fdfs --mount type=volume,source=fdfs_data,target=/var/local fdfs bash
~~~

then, exit the container's bash, query the container record

~~~bash
# in the container
$ exit

# back to the host
$ docker container ls -l
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                     PORTS               NAMES
5e580ff0c7be        fdfs                "/usr/bin/entry.sh b…"   9 seconds ago       Exited (0) 7 seconds ago                       fdfs
~~~

do backup using `--volumes-from`:

~~~bash
$ docker run --name fdfs_bak --volumes-from fdfs -v $(pwd):/backup fdfs tar cvf /backup/backup.tar /var/local
~~~

or just mount the named volume:

~~~bash
$ docker run --name fdfs_bak2 -v fdfs_data:/var/local -v $(pwd):/backup fdfs tar cvf /backup/backup.tar /var/local
~~~

### restore volume data

~~~bash
# on the host, make sure current work directory has the backup.tar
$ ls
backup.tar
# run a container called fdfs_restore, then untar the backup.tar
# cause when execute "tar cvf /backup/backup.tar /var/local", 
# the directory /var/local is also packed in the tar, so when you untar backup.tar, 
# you don't need to specify the destination directory to /var/local
$ docker run --name fdfs_restore -v fdfs_data_restore:/var/local -v $(pwd):/backup fdfs tar xf /backup/backup.tar

# on the host, list the restored files
$ sudo ls /var/lib/docker/volumes/fdfs_data_restore/_data/fdfs/store0/data/00/00
rBEAAl06cziACj-SABMDn32wLzI489_big.jpg	  rBEAAl06cziACj-SABMDn32wLzI489.jpg	rBEAAl06czmAFJZPABMDnwTpr_w794.jpg
rBEAAl06cziACj-SABMDn32wLzI489_big.jpg-m  rBEAAl06cziACj-SABMDn32wLzI489.jpg-m
~~~



