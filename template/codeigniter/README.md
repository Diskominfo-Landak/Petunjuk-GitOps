# Template GitOps: CodeIgniter (Pemkab Landak)

Template ini dirancang untuk aplikasi berbasis CodeIgniter (CodeIgniter 4 atau CodeIgniter 3) di lingkungan Pemkab Landak dengan pola GitOps:
- **Pemisahan Jelas (Folder `src/`)**: Seluruh kode sumber aplikasi CodeIgniter diletakkan di dalam folder `src/`. Berkas konfigurasi Docker & CI/CD berada di root repositori.
- **Tanpa Rahasia di Image**: Tidak ada password/kredensial yang tertanam di Docker image. Seluruh variabel rahasia dimuat saat runtime dari file `.env` di server.
- **CI/CD Otomatis**: Melakukan audit celah keamanan paket (`composer audit`) serta mem-build dan mengunggah image ke `ghcr.io`.

---

## 1. Struktur Direktori Proyek

```text
proyek-ci-anda/
├── Dockerfile                  # Petunjuk build multi-stage Docker (membaca dari folder src/)
├── .dockerignore               # Daftar pengecualian file saat proses docker build
├── .gitignore                  # Mencegah file .env dan vendor ikut ter-commit ke Git
├── .gitattributes              # Menjaga format baris LF pada skrip Linux (.sh)
├── compose.yaml                # Konfigurasi container runtime (app, web, db)
├── compose.build.yaml          # Override untuk build lokal di komputer developer
├── .env.docker.example         # Contoh variabel environment runtime Docker
├── docker/
│   ├── nginx.conf              # Konfigurasi web server Nginx
│   ├── php.ini                 # Konfigurasi runtime PHP-FPM & OPcache
│   └── entrypoint.sh           # Skrip pengaturan izin folder cache/writable
├── .github/
│   └── workflows/
│       └── ci.yml              # Pipeline GitHub Actions ke GHCR
└── src/                        # << TEMPAT KODE SUMBER APLIKASI CODEIGNITER ANDA >>
    ├── app/
    ├── public/
    ├── writable/
    ├── spark
    └── composer.json
```

---

## 2. Cara Memasukkan Kode Proyek Anda ke Folder `src/`

- **Untuk CodeIgniter 4 (Default Bawaan Template)**:
  - Folder `src/` sudah berisi instalasi kerangka CodeIgniter 4 (`codeigniter4/appstarter`) murni.
  - Jika memindahkan proyek CI 4 yang sudah jadi, hapus isi `src/` lalu salin seluruh berkas proyek CI 4 Anda ke dalam `src/`.
- **Untuk CodeIgniter 3 (Aplikasi Warisan / Lama)**:
  1. Hapus isi folder `src/`, lalu salin seluruh berkas proyek CI 3 Anda ke dalam `src/`.
  2. Di file `docker/nginx.conf`, ubah web root dari `/var/www/html/public` menjadi `/var/www/html`, dan ubah `SCRIPT_FILENAME` menjadi `/var/www/html/index.php`.
  3. Di file `compose.yaml`, hapus atau komentari baris volume `- app-writable:/var/www/html/writable`.
  4. Jika aplikasi CI 3 belum kompatibel dengan PHP 8.2, ubah baris `FROM php:8.2-fpm-alpine` pada `Dockerfile` menjadi `FROM php:7.4-fpm-alpine`.

---

## 3. Empat Bagian yang Wajib Disesuaikan di `compose.yaml`

Buka file `compose.yaml` di root proyek Anda, lalu sesuaikan **4 bagian** yang telah diberi penanda `[EDIT 1/4]` sampai `[EDIT 4/4]`:

| Penanda | Baris di `compose.yaml` | Contoh Penggantian | Penjelasan |
|---|---|---|---|
| **`[EDIT 1/4]`** | `name: nama-aplikasi-ci` | `name: simpeg-ci` | Nama proyek Docker Compose di server VM. |
| **`[EDIT 2/4]`** | `image: ghcr.io/diskominfo-landak/nama-aplikasi-ci:${IMAGE_TAG:-development}` | `image: ghcr.io/diskominfo-landak/simpeg-ci:${IMAGE_TAG:-development}` | Sesuaikan `nama-aplikasi-ci` dengan nama repositori GitHub Anda (huruf kecil). |
| **`[EDIT 3/4]`** | Blok `ports:` pada service `web` | `"127.0.0.1:8082:80"` *(Web UI)* **atau** hapus blok `ports:` *(API Service)* | Nomor port di server VM ditentukan oleh Admin Infrastruktur agar tidak bentrok. |
| **`[EDIT 4/4]`** | `aliases:` di bawah `networks.api-net` | `- simpeg-ci-web` | Nama panggilan internal container di jaringan Docker `api-net`. |

---

## 4. Langkah Uji Coba Build di Komputer Lokal

```bash
# 1. Buat jaringan eksternal api-net (cukup dijalankan sekali di komputer Anda)
docker network create api-net 2>/dev/null || true

# 2. Siapkan file .env runtime Docker di root proyek (di luar folder src/)
cp .env.docker.example .env

# 3. Build dan jalankan container secara lokal
docker compose -f compose.yaml -f compose.build.yaml up -d --build

# 4. Periksa status kesehatan container dan log
docker compose ps
docker compose logs -f app
```
