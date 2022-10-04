ARG ALPINE_VERSION=3.16
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Tim de Pater <code@trafex.nl>"
LABEL Description="Lightweight container with Nginx 1.22 & PHP 8.1 based on Alpine Linux."
# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  php81 \
  php81-calendar \
  php81-ctype \
  php81-curl \
  php81-dom \
  php81-exif \
  php81-ffi \
  php81-fileinfo \
  php81-fpm \
  php81-ftp \
  php81-gettext \
  php81-gd \
  php81-iconv \
  php81-intl \
  php81-json \
  php81-mbstring \
  php81-mysqli \
  php81-mysqlnd \
  php81-opcache \
  php81-openssl \
  php81-pcntl \
  php81-pdo_mysql \
  php81-pecl-redis \
  php81-pecl-memcached \
  php81-pecl-xdebug \
  php81-phar \
  php81-posix \
  php81-pspell \
  php81-session \
  php81-shmop \
  php81-simplexml \
  php81-sockets \
  php81-sodium \
  php81-sysvmsg \
  php81-sysvsem \
  php81-sysvshm \
  php81-tokenizer \
  php81-xml \
  php81-xmlreader \
  php81-xmlwriter \
  php81-xsl \
  php81-zip \
  php81-zlib \
  supervisor

# Create symlink so programs depending on `php` still function
RUN ln -s /usr/bin/php81 /usr/bin/php

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php81/php-fpm.d/www.conf
COPY config/php.ini /etc/php81/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
#USER nobody

# Add application
COPY --chown=nobody src/ /var/www/html/

ENV XDEBUG_CONFIG "client_port=9003 log=/var/www/html/xdebug.log"
ENV XDEBUG_MODE "develop,debug"
# Expose the port nginx is reachable on
EXPOSE 8080 9000

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
