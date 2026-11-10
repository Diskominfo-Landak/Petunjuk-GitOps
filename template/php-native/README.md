# Template GitOps PHP Native / Legacy (Pemkab Landak)

Template kontainerisasi siap pakai untuk aplikasi berbasis **PHP Native / Legacy** yang belum menggunakan framework modern, diselaraskan dengan standar GitOps Pemerintah Kabupaten Landak.

---

## 📁 Struktur Direktori

```text
.
├── Dockerfile                  # PHP 8.2-FPM Alpine (ekstensi MySQL, GD, Zip, Opcache)
├── docker/
│   ├── nginx.conf              # Konfigurasi web server Nginx
│   ├── php.ini                 # Pengaturan PHP runtime
│   └── entrypoint.sh           # Inisialisasi permission www-data
├── src/                        # << TEMPAT SELURUH KODE PHP ANDA >>
│   ├── index.php               # Halaman starter & pengecekan DB
│   └── healthz.php             # Endpoint healthcheck JSON
├── compose.yaml                # Konfigurasi container runtime di VM (app, web, db)
├── compose.build.yaml          # Override build lokal di laptop
├── .env.docker.example         # Template variabel environment
├── .github/workflows/ci.yml    # CI: php -l syntax check & build ke GHCR
└── README.md
```

---

## 🚀 Cara Menjalankan di Komputer Lokal

1. Buat jaringan Docker bersama:
   ```bash
   docker network create api-net 2>/dev/null || true
   ```
2. Salin variabel environment:
   ```bash
   cp .env.docker.example .env
   ```
3. Build dan jalankan container lokal:
   ```bash
   docker compose -f compose.yaml -f compose.build.yaml up -d --build
   ```
4. Akses di browser: `http://localhost:8084` atau `http://localhost:8084/healthz.php`.

---

## ⚙️ 4 Titik Edit di `compose.yaml`

Sebelum push ke repositori GitHub:
1. `[EDIT 1/4]` : Ganti nama proyek (`name: nama-aplikasi-php`).
2. `[EDIT 2/4]` : Sesuaikan nama image (`image: ghcr.io/diskominfo-landak/nama-aplikasi-php:${IMAGE_TAG:-development}`).
3. `[EDIT 3/4]` : Alokasikan port lokal (misal `"127.0.0.1:8084:80"`).
4. `[EDIT 4/4]` : Sesuaikan alias jaringan Docker (`- nama-aplikasi-php-web`).
