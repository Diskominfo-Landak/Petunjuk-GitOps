#!/bin/sh
set -e

cd /var/www/html

# Volume storage bisa kosong pada start pertama
mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views \
         storage/logs storage/app/public bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Sinkronisasi aset publik (termasuk hasil Vite build) ke volume bersama untuk Nginx
if [ -d "/var/www/public-shared" ]; then
    cp -rf /var/www/html/public/. /var/www/public-shared/
fi

if [ "$1" = "php-fpm" ]; then
    # Cache dibuat saat container start karena nilai .env baru dimuat saat runtime
    su-exec www-data php artisan config:cache || true
    su-exec www-data php artisan route:cache || true
    su-exec www-data php artisan view:cache || true

    # Jalankan database migration otomatis jika diaktifkan (aman untuk single instance)
    if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
        echo "Menjalankan migrasi database..."
        su-exec www-data php artisan migrate --force

        # Jalankan seeder otomatis HANYA pada deploy awal (ketika tabel users masih kosong)
        # atau jika dipaksa melalui variabel RUN_SEEDERS=true
        if [ "${RUN_SEEDERS:-auto}" = "true" ]; then
            echo "Menjalankan database seeder (RUN_SEEDERS=true)..."
            su-exec www-data php artisan db:seed --force
        elif [ "${RUN_SEEDERS:-auto}" = "auto" ]; then
            USER_COUNT=$(su-exec www-data php artisan tinker --execute="echo \Illuminate\Support\Facades\Schema::hasTable('users') ? \Illuminate\Support\Facades\DB::table('users')->count() : -1;" 2>/dev/null | tr -d '[:space:]' || echo "-1")
            if [ "$USER_COUNT" = "0" ]; then
                echo "Deploy awal terdeteksi (tabel users masih kosong). Menjalankan seeder otomatis..."
                su-exec www-data php artisan db:seed --force
            fi
        fi
    fi
fi

exec "$@"
