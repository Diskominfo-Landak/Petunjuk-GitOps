#!/bin/sh
set -e

cd /var/www/html

# Sinkronisasi aset publik ke volume bersama untuk Nginx
if [ -d "/var/www/public-shared" ] && [ -d "/var/www/html/public" ]; then
    cp -rf /var/www/html/public/. /var/www/public-shared/
fi

# Pastikan folder writable/cache ada dan memiliki izin www-data
if [ -d "writable" ]; then
    # Struktur CodeIgniter 4
    mkdir -p writable/cache writable/logs writable/session writable/uploads
    chown -R www-data:www-data writable

    # Jalankan database migration otomatis jika diaktifkan (khusus CI 4 dengan spark)
    if [ "${RUN_MIGRATIONS:-false}" = "true" ] && [ -f "spark" ]; then
        echo "Menjalankan migrasi database CodeIgniter 4..."
        su-exec www-data php spark migrate --all || true

        if [ "${RUN_SEEDERS:-false}" = "true" ] && [ -n "${CI_SEEDER_CLASS:-}" ]; then
            echo "Menjalankan seeder CodeIgniter 4 (${CI_SEEDER_CLASS})..."
            su-exec www-data php spark db:seed "$CI_SEEDER_CLASS" || true
        fi
    fi
elif [ -d "application/cache" ]; then
    # Struktur CodeIgniter 3
    mkdir -p application/cache application/logs
    chown -R www-data:www-data application/cache application/logs
fi

exec "$@"
