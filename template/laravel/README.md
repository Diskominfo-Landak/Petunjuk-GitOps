# Template GitOps: Laravel 12 (Pemkab Landak)

Template ini dirancang untuk aplikasi berbasis Laravel 12 (PHP 8.3) di lingkungan Pemkab Landak dengan pola GitOps modern:
- **Build Bertahap (Multi-stage)**: Dependensi composer diisolasi dalam build cache, runtime memakai `php:8.3-fpm-alpine`.
- **Aman**: Tanpa secret tertanam dalam image. Secret dikelola via `.env` di server.
- **CI/CD Cepat**: Otomatis build dan push image ke `ghcr.io` menggunakan GitHub Actions runner.
- **Monitoring & Health**: Dilengkapi endpoint pemeriksaan kesehatan `/up`.

---

## Struktur File yang Perlu Disalin ke Proyek Laravel Anda

Salin file-file berikut ke root proyek Laravel Anda:

```text
proyek-laravel-anda/
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

## Langkah Penerapan pada Proyek Laravel Baru

1. **Sesuaikan Nama Aplikasi dan Image:**
   - Di file `compose.yaml`:
     - Ganti `name: nama-aplikasi`
     - Ganti image: `ghcr.io/diskominfo-landak/nama-repo:${IMAGE_TAG:-development}`
     - Tentukan apakah aplikasi berupa Web UI (buka port `127.0.0.1:808X:80`) atau API internal (tutup port host).
2. **Pastikan Endpoint Healthcheck Aktif:**
   - Laravel 11/12 secara default sudah memiliki endpoint `/up`. Pastikan dapat diakses tanpa autentikasi.
3. **Uji Coba Build Lokal di Laptop:**
   ```bash
   docker compose -f compose.yaml -f compose.build.yaml up --build
   ```
4. **Push ke GitHub:**
   - Push commit ke branch `development`.
   - Periksa tab **Actions** di GitHub. Workflow CI akan menjalankan unit test, audit keamanan, dan mem-push image ke GHCR.
