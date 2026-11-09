# syntax=docker/dockerfile:1

# ---- Tahap 1: pasang dependensi Composer jika ada composer.json ----
FROM composer:2 AS vendor
WORKDIR /app
COPY src/composer.json* src/composer.lock* ./
RUN if [ -f composer.json ]; then \
      composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction --ignore-platform-reqs; \
    else \
      mkdir -p vendor; \
    fi
COPY src/ ./
RUN if [ -f composer.json ]; then \
      composer dump-autoload --no-dev --optimize --classmap-authoritative --no-scripts --ignore-platform-reqs; \
    fi

# ---- Tahap 2: image runtime (PHP-FPM Alpine) ----
FROM php:8.2-fpm-alpine AS app

RUN apk add --no-cache su-exec icu-dev libpng-dev libzip-dev \
    && docker-php-ext-install -j"$(nproc)" pdo_mysql mysqli intl gd zip opcache \
    && cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY docker/php.ini "$PHP_INI_DIR/conf.d/zz-app.ini"

WORKDIR /var/www/html
COPY --from=vendor /app/ ./

COPY docker/entrypoint.sh /usr/local/bin/entrypoint
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint \
    && chmod +x /usr/local/bin/entrypoint \
    && chown -R www-data:www-data /var/www/html

ENTRYPOINT ["entrypoint"]
CMD ["php-fpm"]
