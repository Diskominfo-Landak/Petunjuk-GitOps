# Template GitOps: CodeIgniter (Pemkab Landak)

Template ini dirancang untuk aplikasi berbasis CodeIgniter (CI 4 atau CI 3) di lingkungan Pemkab Landak.

---

## Struktur File yang Perlu Disalin ke Proyek CodeIgniter

```text
proyek-ci-anda/
├── Dockerfile
├── compose.yaml
├── compose.build.yaml
├── .env.docker.example
├── docker/
│   ├── nginx.conf
│   ├── php.ini
│   └── entrypoint.sh
└── .github/
    └── workflows/
        └── ci.yml
```

---

## Penyesuaian Penting (CI 4 vs CI 3)

1. **Untuk CodeIgniter 4 (Default Template):**
   - Web root terletak di `/var/www/html/public`.
   - File konfigurasi Nginx dan path index sudah mengarah ke folder `public`.
2. **Untuk CodeIgniter 3 (Versi Lama):**
   - Di file `docker/nginx.conf`, ubah root dari `/var/www/html/public` menjadi `/var/www/html`.
   - Ubah `SCRIPT_FILENAME` dari `/var/www/html/public/index.php` menjadi `/var/www/html/index.php`.
   - Jika aplikasi membutuhkan PHP 7.4, sesuaikan baris pertama Dockerfile (`FROM php:7.4-fpm-alpine`).
3. **Database:**
   - Gunakan `DBDriver = MySQLi` atau `pdo` pada konfigurasi database aplikasi CodeIgniter Anda.
