# Template GitOps: CodeIgniter (Pemkab Landak)

Template ini dirancang untuk aplikasi berbasis CodeIgniter (CodeIgniter 4 atau CodeIgniter 3) di lingkungan Pemkab Landak dengan pola GitOps:
- **Pemisahan Jelas (Folder `src/`)**: Seluruh kode sumber aplikasi CodeIgniter diletakkan di dalam folder `src/`. Berkas konfigurasi Docker & CI/CD berada di root repositori.
- **Tanpa Rahasia di Image**: Tidak ada password/kredensial yang tertanam di Docker image. Seluruh variabel rahasia dimuat saat runtime dari file `.env` di server.
- **Migrasi Otomatis (CI 4)**: Mendukung eksekusi migrasi database otomatis saat container start (`php spark migrate --all`).
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
│   ├── nginx.conf              # Konfigurasi web server Nginx (termasuk static assets)
│   ├── php.ini                 # Konfigurasi runtime PHP-FPM & OPcache
│   └── entrypoint.sh           # Skrip izin folder cache/writable, sync public, & auto-migration
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
  3. Di file `compose.yaml`, hapus atau komentari baris volume `- app-writable:/var/www/html/writable` dan ganti mount `app-public` dengan `- ./src:/var/www/html:ro` pada service `web`.
  4. Jika aplikasi CI 3 belum kompatibel dengan PHP 8.2, ubah baris `FROM php:8.2-fpm-alpine` pada `Dockerfile` menjadi `FROM php:7.4-fpm-alpine`.

---

## 3. Pengelolaan Database, `.env.docker.example`, & Migrasi

### A. Aturan File `.env.docker.example`:
1. **Default Produksi**: Biarkan `CI_ENVIRONMENT=production` dan isi `app.baseURL` langsung dengan alamat subdomain produksi resmi (misal `https://simpeg.landakkab.go.id`).
2. **Aturan Database Docker**:
   - **`database.default.hostname=db`**: Wajib diisi `db` (nama service container), jangan diisi `127.0.0.1` atau `localhost`.
   - **`DB_USERNAME` / `database.default.username`**: Wajib menggunakan nama user biasa (misal `db_user`), **dilarang keras mengisi `root`** karena container MySQL menolak nilai `MYSQL_USER="root"`.
3. **Nilai Dummy**: Jangan pernah menulis password asli di `.env.docker.example`.

### B. Untuk CodeIgniter 4 (Menggunakan Migration & Seeder):
CodeIgniter 4 memiliki CLI bernama **`spark`**.
1. **Membuat File Migrasi Baru**:
   ```bash
   cd src
   php spark make:migration NamaTabelBaru
   ```
2. **Eksekusi Otomatis di Server**:
   - Di `compose.yaml` sudah terpasang `RUN_MIGRATIONS: "true"`, sehingga `entrypoint.sh` otomatis menjalankan `php spark migrate --all` saat container menyala.
   - Jika ingin menjalankan seeder awal secara otomatis, Anda dapat mengisi `RUN_SEEDERS: "true"` dan `CI_SEEDER_CLASS: "DatabaseSeeder"` pada environment `app`.

---

## 4. Empat Bagian yang Wajib Disesuaikan di `compose.yaml`

Buka file `compose.yaml` di root proyek Anda, lalu sesuaikan **4 bagian** yang telah diberi penanda `[EDIT 1/4]` sampai `[EDIT 4/4]`:

| Penanda | Baris di `compose.yaml` | Contoh Penggantian | Penjelasan |
|---|---|---|---|
| **`[EDIT 1/4]`** | `name: nama-aplikasi-ci` | `name: simpeg` | Nama proyek Docker Compose di server VM. |
| **`[EDIT 2/4]`** | `image: ghcr.io/diskominfo-landak/nama-aplikasi-ci:${IMAGE_TAG:-development}` | `image: ghcr.io/diskominfo-landak/simpeg:${IMAGE_TAG:-development}` | Sesuaikan dengan nama repositori GitHub Anda (huruf kecil). |
| **`[EDIT 3/4]`** | Blok `ports:` pada service `web` | `"127.0.0.1:8082:80"` *(Web UI)* **atau** hapus blok `ports:` *(API Service)* | Nomor port ditentukan 1 kali di awal bersama Admin Infrastruktur dan **tidak perlu diubah** saat merge ke `main`. |
| **`[EDIT 4/4]`** | `aliases:` di bawah `networks.api-net` | `- simpeg-web` | Nama panggilan internal container di jaringan Docker `api-net`. |

---

## 5. Pengujian & Publikasi (Pilih Sesuai Spesifikasi Laptop Anda)

### Jalur A: Laptop Tanpa Docker (Langsung Push ke GitHub)

Jika komputer Anda belum terpasang Docker (hanya menggunakan Laragon / XAMPP):

1. **Langkah 1 — Minta Nama Repositori & Hak Akses ke Admin GitOps**:
   - Sampaikan username akun GitHub Anda kepada **Admin GitOps**.
   - Admin GitOps akan membuatkan repositori resmi di `https://github.com/Diskominfo-Landak/<nama-repo>` sesuai nama subdomain yang disepakati (misal: `simpeg`), serta menambahkan akun Anda sebagai kolaborator.
   - Minta juga alokasi **nomor port upstream** internal (misal: `8082`) untuk diisi pada penanda `[EDIT 3/4]` di `compose.yaml`.

2. **Langkah 2 — Pastikan Aplikasi Lokal Siap**:
   - Pastikan aplikasi di folder `src/` dan seluruh migrasinya berjalan normal di Laragon/XAMPP (`php spark migrate`).
   - Pastikan ke-4 titik `[EDIT 1/4]` s.d. `[EDIT 4/4]` di `compose.yaml` dan `.env.docker.example` sudah disesuaikan dengan `<nama-repo>`.

3. **Langkah 3 — Tutorial Inisialisasi Git Remote & Push Pertama Kali**:
   Ikuti langkah berikut agar tidak bingung saat pertama kali menghubungkan laptop ke repositori GitHub organisasi:
   ```bash
   # 1. Buka terminal di root direktori proyek (bukan di dalam folder src/)
   cd /path/ke/proyek-ci   # misal: cd C:\laragon\www\simpeg

   # 2. Inisialisasi git lokal jika belum ada
   git init

   # 3. Buat dan berpindah ke branch 'development'
   git checkout -b development

   # 4. Hubungkan remote repository GitHub:
   # Periksa apakah remote 'origin' sudah pernah disetel sebelumnya:
   git remote -v

   # Jika BELUM ADA remote, tambahkan URL repo dari Admin GitOps:
   git remote add origin https://github.com/Diskominfo-Landak/<nama-repo>.git

   # Jika SUDAH ADA remote lama (misal sisa clone template), ubah URL-nya:
   git remote set-url origin https://github.com/Diskominfo-Landak/<nama-repo>.git

   # 5. Pastikan file rahasia .env lokal TIDAK ikut ter-commit:
   git status

   # 6. Tambahkan seluruh berkas dan commit perdana:
   git add .
   git commit -m "feat: inisialisasi proyek codeigniter dengan template gitops"

   # 7. Push PERDANA ke branch development dengan flag '-u' (upstream):
   git push -u origin development
   ```
   > 💡 **Catatan Flag `-u` (`--set-upstream`)**:
   > Perintah `git push -u origin development` hanya dijalankan **1 kali di awal** untuk mengaitkan branch lokal ke GitHub. Untuk push fitur harian berikutnya, Anda cukup mengetik:
   > ```bash
   > git push
   > ```

4. **Langkah 4 — Pantau CI/CD GitHub Actions**:
   Buka tab **Actions** di repositori GitHub Anda. GitHub Actions akan otomatis mem-build Docker image (`ghcr.io/diskominfo-landak/<nama-repo>:development`), dan Server VM Development akan otomatis menarik image serta menyalakan aplikasi di `https://<nama-repo>-dev.landakkab.go.id`!

---

### Jalur B: Uji Coba Container di Komputer Lokal (Jika Memiliki Docker)

> **Catatan Pengguna WSL 2 (Ubuntu)**: Jika Docker Anda terpasang di dalam distro Ubuntu WSL 2, jalankan seluruh perintah di bawah ini dari terminal Ubuntu WSL (`cd /mnt/c/laragon/www/nama-proyek`).

#### 1. Buat Jaringan Eksternal `api-net` & Salin File `.env`

**Opsi Terminal Linux / macOS / WSL 2 (Ubuntu):**
```bash
docker network create api-net 2>/dev/null || true
cp .env.docker.example .env
```

**Opsi Terminal Windows PowerShell:**
```powershell
docker network create api-net
Copy-Item .env.docker.example .env
```

#### 2. Build dan Jalankan Container
```bash
docker compose -f compose.yaml -f compose.build.yaml up -d --build
```

#### 3. Periksa Status Kesehatan Container & Log
```bash
docker compose ps
docker compose logs -f app
```
