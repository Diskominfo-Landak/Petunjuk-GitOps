#!/bin/sh
set -e

cd /var/www/html

# Volume storage bisa kosong pada start pertama
mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views \
         storage/logs storage/app/public bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

if [ "$1" = "php-fpm" ]; then
    # Cache dibuat saat container start karena nilai .env baru dimuat saat runtime
    su-exec www-data php artisan config:cache || true
    su-exec www-data php artisan route:cache || true
    su-exec www-data php artisan view:cache || true

    # Jalankan database migration otomatis jika diaktifkan (aman untuk single instance)
    if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
        echo "Menjalankan migrasi database..."
        su-exec www-data php artisan migrate --force
    fi
fi

exec "$@"
