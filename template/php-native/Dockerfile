# syntax=docker/dockerfile:1

FROM php:8.2-fpm-alpine AS app

RUN apk add --no-cache su-exec libpng-dev libzip-dev \
    && docker-php-ext-install -j"$(nproc)" pdo_mysql mysqli gd zip opcache \
    && cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY docker/php.ini "$PHP_INI_DIR/conf.d/zz-app.ini"

WORKDIR /var/www/html
COPY src/ ./

COPY docker/entrypoint.sh /usr/local/bin/entrypoint
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint \
    && chmod +x /usr/local/bin/entrypoint \
    && chown -R www-data:www-data /var/www/html

ENTRYPOINT ["entrypoint"]
CMD ["php-fpm"]
