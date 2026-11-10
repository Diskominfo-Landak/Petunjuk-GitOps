#!/bin/sh
set -e

# Pastikan kepemilikan folder html sesuai dengan www-data
chown -R www-data:www-data /var/www/html 2>/dev/null || true

exec "$@"
