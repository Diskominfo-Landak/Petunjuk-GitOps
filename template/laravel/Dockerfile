# syntax=docker/dockerfile:1

# ---- Tahap 1: pasang dependensi PHP (tanpa paket development) ----
FROM composer:2 AS vendor
WORKDIR /app
COPY src/composer.json src/composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction --ignore-platform-reqs
COPY src/ ./
RUN composer dump-autoload --no-dev --optimize --classmap-authoritative --no-scripts --ignore-platform-reqs

# ---- Tahap 2: build aset frontend Vite / Tailwind (jika ada package.json) ----
FROM node:22-alpine AS frontend
WORKDIR /app
COPY src/package*.json ./
RUN if [ -f package.json ]; then npm ci --no-audit --no-fund || npm install --no-audit --no-fund; fi
COPY src/ ./
RUN mkdir -p /app/public/build \
    && if [ -f package.json ] && grep -q '"build"' package.json; then npm run build; fi

# ---- Tahap 3: image runtime (PHP-FPM Alpine) ----
FROM php:8.3-fpm-alpine AS app

RUN apk add --no-cache su-exec \
    && docker-php-ext-install -j"$(nproc)" pdo_mysql opcache \
    && cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY docker/php.ini "$PHP_INI_DIR/conf.d/zz-app.ini"

WORKDIR /var/www/html
COPY --from=vendor /app/ ./
COPY --from=frontend /app/public/build ./public/build

COPY docker/entrypoint.sh /usr/local/bin/entrypoint
# Pastikan baris akhir Linux (LF) agar tidak error jika di-build dari Windows
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint \
    && chmod +x /usr/local/bin/entrypoint \
    && mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs storage/app/public bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

ENTRYPOINT ["entrypoint"]
CMD ["php-fpm"]
