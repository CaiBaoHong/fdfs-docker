FROM ubuntu:18.04

# variables for installation
ARG SOURCE_DIR=/usr/local/src
ARG BUILD_DEPS='make cmake gcc libpcre3 libpcre3-dev zlib1g zlib1g-dev net-tools vim'
ARG NGINX=nginx-1.17.1
ARG FDFS_COMMON=libfastcommon-1.0.39
ARG FDFS_NGINX=fastdfs-nginx-module-1.20
ARG FDFS=fastdfs-5.11
ARG FDHT=fastdht-master
ARG BKDB=db-4.7.25
ENV FDFS_DATA_DIR=/var/local/fdfs
ENV FDFS_CONF_DIR=/etc/fdfs
ENV FDHT_DATA_DIR=/var/local/fdht
ENV FDHT_CONF_DIR=/etc/fdht
ENV STORAGE_PORT=23000
ENV STORAGE_HTTP_PORT=8888
ENV TRACKER_PORT=22122
ENV TRACKER_HTTP_PORT=8080
ENV FDHT_PORT=11411

# copy files
COPY files/                     $SOURCE_DIR
COPY entry.sh                   /usr/bin

################################################## all install steps ###################################################
RUN cd $SOURCE_DIR                                                                                                     \
                                                                                                                       \
# extra files                                                                                                          \
    && for tar in *.tar.gz; do tar -xzf $tar; done && rm *.tar.gz                                                      \
                                                                                                                       \
# copy special files to destination dir                                                                                \
    && mv sources.list  /etc/apt/sources.list                                                                          \
    && mv fdfs          /usr/bin/fdfs                                                                                  \
    && mkdir -p         $FDFS_CONF_DIR                                                                                 \
    && mkdir -p         $FDHT_CONF_DIR                                                                                 \
    && mkdir -p         $FDFS_DATA_DIR/store0                                                                          \
    && mkdir -p         $FDHT_DATA_DIR                                                                                 \
    && mv test.jpg      $FDFS_CONF_DIR/test.jpg                                                                        \
                                                                                                                       \
# update apt repo, install depended softwares                                                                          \
    && apt-get update && apt-get install -y $BUILD_DEPS                                                                \
                                                                                                                       \
# install libfastcommon                                                                                                \
    && cd $SOURCE_DIR/$FDFS_COMMON && ./make.sh && ./make.sh install                                                   \
                                                                                                                       \
# install fastdfs                                                                                                      \
    && cd $SOURCE_DIR/$FDFS && ./make.sh && ./make.sh install                                                          \
                                                                                                                       \
# fix a installation bug of fastdfs-nginx-module                                                                       \
    && sed -i "s|/usr/local/include|/usr/include/fastdfs /usr/include/fastcommon|g" $SOURCE_DIR/$FDFS_NGINX/src/config \
                                                                                                                       \
# install nginx with module                                                                                            \
    && cd $SOURCE_DIR/$NGINX && ./configure --add-module=$SOURCE_DIR/$FDFS_NGINX/src                                   \
                                            --sbin-path=/usr/sbin/nginx                                                \
                                            --conf-path=/etc/nginx/nginx.conf                                          \
                                            --error-log-path=/var/log/nginx/error.log                                  \
                                            --pid-path=/var/log/nginx/nginx.pid                                        \
                                            --http-log-path=/var/log/nginx/access.log                                  \
    && make && make install                                                                                            \
                                                                                                                       \
# install Berkeley DB                                                                                                  \
    && cd $SOURCE_DIR/$BKDB/build_unix && ../dist/configure --prefix=/usr && make && make install                      \
                                                                                                                       \
# install fastdht                                                                                                      \
    && cd $SOURCE_DIR/$FDHT && ./make.sh && ./make.sh install                                                          \
                                                                                                                       \
# post installation                                                                                                    \
                                                                                                                       \
### overwrite nginx conf file, copy fdfs and fastdfs-nginx-module conf file                                            \
    && mv $SOURCE_DIR/nginx.conf                        /etc/nginx/nginx.conf                                          \
    && cp $SOURCE_DIR/$FDFS/conf/*                      $FDFS_CONF_DIR                                                 \
    && cp $SOURCE_DIR/$FDFS_NGINX/src/mod_fastdfs.conf  $FDFS_CONF_DIR                                                 \
                                                                                                                       \
### modify config files                                                                                                \
    && sed -i "s|^base_path=.*$|base_path=$FDFS_DATA_DIR|g"                     $FDFS_CONF_DIR/mod_fastdfs.conf        \
    && sed -i "s|^base_path=.*$|base_path=$FDFS_DATA_DIR|g"                     $FDFS_CONF_DIR/storage.conf            \
    && sed -i "s|^base_path=.*$|base_path=$FDFS_DATA_DIR|g"                     $FDFS_CONF_DIR/tracker.conf            \
    && sed -i "s|^base_path=.*$|base_path=$FDFS_DATA_DIR|g"                     $FDFS_CONF_DIR/client.conf             \
    && sed -i "s|^store_path0=.*$|store_path0=$FDFS_DATA_DIR/store0|g"          $FDFS_CONF_DIR/storage.conf            \
    && sed -i "s|^store_path0=.*$|store_path0=$FDFS_DATA_DIR/store0|g"          $FDFS_CONF_DIR/mod_fastdfs.conf        \
    && sed -i "s|^base_path=.*$|base_path=$FDHT_DATA_DIR|g"                     $FDHT_CONF_DIR/fdht_client.conf        \
    && sed -i "s|^base_path=.*$|base_path=$FDHT_DATA_DIR|g"                     $FDHT_CONF_DIR/fdhtd.conf              \
    && sed -i "4d"                                                              $FDHT_CONF_DIR/fdht_servers.conf       \
    && sed -i "s|^check_file_duplicate=.*$|check_file_duplicate=1|g"            $FDFS_CONF_DIR/storage.conf            \
    && sed -i "s|^keep_alive=.*$|keep_alive=1|g"                                $FDFS_CONF_DIR/storage.conf            \
    && sed -i "s|^##include.*$|#include ${FDHT_CONF_DIR}/fdht_servers.conf|g"   $FDFS_CONF_DIR/storage.conf            \
## remove unnecessary resources                                                                                        \
    && rm -rf $SOURCE_DIR/*                                                                                            \
    && rm -rf $FDFS_CONF_DIR/*.sample

########################################################################################################################

# expose fdfs data dir
VOLUME $FDFS_DATA_DIR

EXPOSE $STORAGE_PORT $TRACKER_PORT $FDHT_PORT

ENTRYPOINT ["/usr/bin/entry.sh"]
