#!/bin/sh
set -e

cd /var/www/html

# Pastikan folder writable/cache ada dan memiliki izin www-data
if [ -d "writable" ]; then
    # Struktur CodeIgniter 4
    mkdir -p writable/cache writable/logs writable/session writable/uploads
    chown -R www-data:www-data writable

    # Jalankan database migration otomatis jika diaktifkan (khusus CI 4 dengan spark)
    if [ "${RUN_MIGRATIONS:-false}" = "true" ] && [ -f "spark" ]; then
        echo "Menjalankan migrasi database CodeIgniter 4..."
        su-exec www-data php spark migrate --all || true
    fi
elif [ -d "application/cache" ]; then
    # Struktur CodeIgniter 3
    mkdir -p application/cache application/logs
    chown -R www-data:www-data application/cache application/logs
fi

exec "$@"
