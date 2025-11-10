FROM debian:bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    bash \
    ca-certificates \
    php7.4 \
    php7.4-fpm \
    php7.4-mysqli \
    default-mysql-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

WORKDIR /var/www/html/

COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d/

RUN mkdir -p /run/php

COPY ./tools/create_wordpress.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/create_wordpress.sh

ENTRYPOINT ["/usr/local/bin/create_wordpress.sh"]

EXPOSE 9000

CMD ["/usr/sbin/php-fpm7.4", "-F"]
