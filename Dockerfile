FROM ubuntu:18.04

# arguments
ARG APP_ENV=local
ARG SERVER_NAME=local.psq.streaming.com
ARG GIT_ROOT=/git
ARG RTMP_NGINX_MODULE_HOME=$GIT_ROOT/nginx-rtmp-module
ARG NGINX_HOME=/etc/nginx
ARG PSQ_API_HOST=local.psq.api.com
ARG NGINX_VERSION=1.14.0

# env variables
ENV DEBIAN_FRONTEND=noninteractive
ENV APP_ENV=$APP_ENV
ENV SERVER_NAME=$SERVER_NAME
ENV PSQ_API_HOST=$PSQ_API_HOST
ENV RTMP_NGINX_MODULE_HOME=$RTMP_NGINX_MODULE_HOME
ENV NGINX_HOME=$NGINX_HOME

# base packages

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get -y install git wget gnupg apt-utils software-properties-common tar zip curl lsof nano htop \
    unzip build-essential ufw apt-utils sed iputils-ping net-tools gcc make libpcre3-dev libssl-dev \
    zlibc zlib1g zlib1g-dev ffmpeg

# build custom nginx

RUN mkdir -p $GIT_ROOT

WORKDIR $GIT_ROOT
# clone custom RMPT NGINX MODULE
RUN git clone https://github.com/ut0mt8/nginx-rtmp-module.git

# BUILD CUSTOM NGINX
RUN wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
tar zxpvf nginx-$NGINX_VERSION.tar.gz && \
cd nginx-$NGINX_VERSION && \
./configure --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx \
--modules-path=/usr/lib/nginx/modules --conf-path=$NGINX_HOME/nginx.conf \
--error-log-path=/var/log/nginx/error.log   --http-log-path=/var/log/nginx/access.log \
--pid-path=/run/nginx.pid --lock-path=/var/lock/nginx.lock --user=www-data --group=www-data \
--build=Ubuntu --with-http_ssl_module --with-http_secure_link_module --add-module=$RTMP_NGINX_MODULE_HOME && \
make && \
make install

RUN  if [ "$APP_ENV" = "local" ] ; then \
mkdir -p /etc/ssl/live/streaming.psq.com && \
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-subj "/C=AR/ST=BuenosAires/L=BuenosAires/O=PSQ/OU=IT Department/CN=${SERVER_NAME}" \
-keyout /etc/ssl/live/streaming.psq.com/privkey.pem \
-out /etc/ssl/live/streaming.psq.com/fullchain.pem; \
fi

# nginx config files
RUN mkdir -p /etc/ssl && cd /etc/ssl && openssl dhparam -out ssl-dhparams.pem 2048

RUN mkdir $NGINX_HOME/sites-available && \
    mkdir $NGINX_HOME/sites-enabled && \
    mkdir $NGINX_HOME/conf.d && \
    mkdir $NGINX_HOME/snippets && \
    mkdir $NGINX_HOME/ssl

COPY nginx/nginx.conf $NGINX_HOME/nginx.conf
COPY nginx/ext/rtmp-server.conf $NGINX_HOME/ext/rtmp-server.conf
COPY nginx/snippets/letsencrypt.conf $NGINX_HOME/snippets/letsencrypt.conf
COPY nginx/sites-available/streaming.psq.com.conf $NGINX_HOME/sites-available/streaming.psq.com

SHELL ["/bin/bash", "-c"]

RUN sed -i "s/@SERVER_NAME/$SERVER_NAME/g" $NGINX_HOME/ext/rtmp-server.conf
RUN sed -i "s/@PSQ_API_HOST/$PSQ_API_HOST/g" $NGINX_HOME/ext/rtmp-server.conf

RUN sed -i "s/@SERVER_NAME/$SERVER_NAME/g" $NGINX_HOME/sites-available/streaming.psq.com
RUN RTMP_NGINX_MODULE_HOME_1=${RTMP_NGINX_MODULE_HOME////\\/} && \
echo $RTMP_NGINX_MODULE_HOME_1 && \
sed -i "s/@RTMP_NGINX_MODULE_HOME/$RTMP_NGINX_MODULE_HOME_1/g" $NGINX_HOME/sites-available/streaming.psq.com
RUN ln -s $NGINX_HOME/sites-available/streaming.psq.com $NGINX_HOME/sites-enabled/streaming.psq.com

RUN git clone https://github.com/Fleshgrinder/nginx-sysvinit-script.git && \
cd nginx-sysvinit-script && \
make

# entry point
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod 777 /usr/local/bin/docker-entrypoint.sh \
    && ln -s /usr/local/bin/docker-entrypoint.sh /

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/bin/bash"]

EXPOSE 443
EXPOSE 80
EXPOSE 1935
