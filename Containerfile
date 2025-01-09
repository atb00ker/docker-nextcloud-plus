FROM docker.io/nextcloud:stable-fpm-alpine

# Since upstream wouldn't do it:
# https://github.com/nextcloud/docker/issues/1969
ENV PHP_PM_MAX_CHILDREN=5
ENV PHP_PM_START_SERVERS=2
ENV PHP_PM_MIN_SPARE_SERVERS=1
ENV PHP_PM_MAX_SPARE_SERVERS=3

RUN set -eux; \
    { \
    echo '[www]'; \
    echo 'pm.max_children = ${PHP_PM_MAX_CHILDREN}'; \
    echo 'pm.start_servers = ${PHP_PM_START_SERVERS}'; \
    echo 'pm.min_spare_servers = ${PHP_PM_MIN_SPARE_SERVERS}'; \
    echo 'pm.max_spare_servers = ${PHP_PM_MAX_SPARE_SERVERS}'; \
    } | tee "/usr/local/etc/php-fpm.d/additional-config.conf"

RUN set -ex; \
    \
    apk add --no-cache \
    ffmpeg \
    perl \
    exiftool \
    go \
    curl \
    imagemagick \
    samba-client;

RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    imap-dev \
    openssl-dev \
    samba-dev \
    bzip2-dev \
    ; \
    \
    docker-php-ext-install \
    bz2 \
    imap \
    ; \
    pecl install smbclient; \
    docker-php-ext-enable smbclient; \
    \
    runDeps="$( \
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
    | tr ',' '\n' \
    | sort -u \
    | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .nextcloud-phpext-rundeps $runDeps; \
    apk del .build-deps
