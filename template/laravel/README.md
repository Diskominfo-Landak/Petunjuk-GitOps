# Template GitOps: Laravel (Pemkab Landak)

Template ini dirancang untuk aplikasi berbasis Laravel (PHP 8.3 + MySQL 8.4) di lingkungan Pemkab Landak dengan pola GitOps modern:
- **Pemisahan Jelas (Folder `src/`)**: Seluruh kode sumber aplikasi Laravel diletakkan di dalam folder `src/`. Berkas konfigurasi Docker & CI/CD berada di root repositori.
- **Build Bertahap (Multi-stage)**: Dependensi Composer diisolasi dalam tahap build, sedangkan runtime memakai `php:8.3-fpm-alpine` yang ringan dan aman.
- **Tanpa Rahasia di Image**: Tidak ada password/kredensial yang tertanam di Docker image. Seluruh variabel rahasia dimuat saat runtime dari file `.env` di server.
- **CI/CD Otomatis**: Menjalankan unit test, audit celah keamanan (`composer audit`), serta mem-build dan mengunggah image ke `ghcr.io`.

---

## 1. Struktur Direktori Proyek

```text
proyek-laravel-anda/
├── Dockerfile                  # Petunjuk build multi-stage Docker (membaca dari folder src/)
├── .dockerignore               # Daftar pengecualian file saat proses docker build
├── .gitignore                  # Mencegah file .env dan vendor ikut ter-commit ke Git
├── .gitattributes              # Menjaga format baris LF pada skrip Linux (.sh)
├── compose.yaml                # Konfigurasi container runtime (app, web, db)
├── compose.build.yaml          # Override untuk build lokal di komputer developer
├── .env.docker.example         # Contoh variabel environment runtime Docker
├── docker/
│   ├── nginx.conf              # Konfigurasi web server internal Nginx
│   ├── php.ini                 # Konfigurasi runtime PHP-FPM & OPcache
│   └── entrypoint.sh           # Skrip inisialisasi cache & migrasi saat container start
├── .github/
│   └── workflows/
│       └── ci.yml              # Pipeline GitHub Actions (Test, Audit, GHCR Push)
└── src/                        # << TEMPAT KODE SUMBER APLIKASI LARAVEL ANDA >>
    ├── app/
    ├── bootstrap/
    ├── config/
    ├── database/
    ├── public/
    ├── resources/
    ├── routes/
    ├── tests/
    ├── artisan
    └── composer.json
```

---

## 2. Cara Memasukkan Kode Proyek Anda ke Folder `src/`

- **Jika Memulai Proyek Baru dari Nol**:
  Folder `src/` pada template ini sudah berisi instalasi kerangka Laravel murni yang siap langsung Anda kembangkan.
- **Jika Memindahkan Proyek Laravel yang Sudah Jadi**:
  1. Hapus seluruh isi di dalam folder `src/`.
  2. Salin seluruh berkas proyek Laravel Anda ke dalam folder `src/` (pastikan file `artisan` dan `composer.json` berada tepat di `src/artisan` dan `src/composer.json`).
  3. Pastikan endpoint kesehatan `/up` aktif (bawaan default Laravel 11+ di `bootstrap/app.php` melalui `health: '/up'`).

---

## 3. Empat Bagian yang Wajib Disesuaikan di `compose.yaml`

Buka file `compose.yaml` di root proyek Anda, lalu sesuaikan **4 bagian** yang telah diberi penanda `[EDIT 1/4]` sampai `[EDIT 4/4]`:

| Penanda | Baris di `compose.yaml` | Contoh Penggantian | Penjelasan |
|---|---|---|---|
| **`[EDIT 1/4]`** | `name: nama-aplikasi` | `name: finda-app` | Nama proyek Docker Compose di server VM. |
| **`[EDIT 2/4]`** | `image: ghcr.io/diskominfo-landak/nama-aplikasi:${IMAGE_TAG:-development}` | `image: ghcr.io/diskominfo-landak/finda-app:${IMAGE_TAG:-development}` | Sesuaikan `nama-aplikasi` dengan nama repositori GitHub Anda (huruf kecil). |
| **`[EDIT 3/4]`** | Blok `ports:` pada service `web` | `"127.0.0.1:8081:80"` *(Web UI)* **atau** hapus blok `ports:` *(API Service)* | Lihat penjelasan **Opsi Port** di bawah. |
| **`[EDIT 4/4]`** | `aliases:` di bawah `networks.api-net` | `- finda-app-web` | Nama panggilan internal container di jaringan Docker `api-net`. |

### Penjelasan Khusus `[EDIT 3/4]` (Pilihan Port Web UI vs API Service):
1. **Jika Aplikasi Web Pengguna (Human-facing, memiliki halaman login/UI)**:
   - Pertahankan blok `ports: - "127.0.0.1:8081:80"`.
   - Saat diuji di laptop lokal, Anda bebas menggunakan port berapa saja yang kosong (misal `8081`).
   - Saat akan dipasang ke Server VM, **koordinasikan nomor port tersebut dengan Admin Infrastruktur** (agar tidak bentrok dengan aplikasi OPD lain di VM yang sama dan agar didaftarkan ke Reverse Proxy domain `.landakkab.go.id`).
2. **Jika Layanan API Internal (Machine-to-Machine di belakang `api-gateway`)**:
   - **Hapus** atau beri tanda komentar (`#`) pada baris `ports:` dan `- "127.0.0.1:8081:80"`, sehingga menjadi:
     ```yaml
     volumes:
       - ./docker/nginx.conf:/etc/nginx/conf.d/default.conf:ro
       - app-storage:/var/www/storage:ro
     networks:
       internal:
       api-net:
         aliases:
           - nama-aplikasi-web
     ```
   - Dengan menutup port host, layanan API Anda terlindungi dan hanya bisa diakses melalui `api-gateway` lewat jaringan internal `api-net` menggunakan nama alias (`http://nama-aplikasi-web`).

---

## 4. Langkah Uji Coba Build di Komputer Lokal

Sebelum mem-push ke GitHub, pastikan aplikasi berjalan baik di dalam Docker lokal Anda:

```bash
# 1. Buat jaringan eksternal api-net (cukup dijalankan sekali di komputer Anda)
docker network create api-net 2>/dev/null || true

# 2. Siapkan file .env runtime Docker di root proyek (di luar folder src/)
cp .env.docker.example .env
# Edit file .env dan isi APP_KEY (bisa disalin dari src/.env lokal Anda)

# 3. Build dan jalankan container secara lokal
docker compose -f compose.yaml -f compose.build.yaml up -d --build

# 4. Periksa status kesehatan container dan log
docker compose ps
docker compose logs -f app
```

Jika aplikasi Web UI dibuka di port `8081`, uji melalui browser di `http://localhost:8081` dan pastikan `http://localhost:8081/up` menampilkan status sehat (HTTP 200).
