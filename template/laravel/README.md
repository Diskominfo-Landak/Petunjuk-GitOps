# Template GitOps: Laravel (Pemkab Landak)

Template ini dirancang untuk aplikasi berbasis Laravel (PHP 8.3 + MySQL 8.4) di lingkungan Pemkab Landak dengan pola GitOps modern:
- **Pemisahan Jelas (Folder `src/`)**: Seluruh kode sumber aplikasi Laravel diletakkan di dalam folder `src/`. Berkas konfigurasi Docker & CI/CD berada di root repositori.
- **Build Bertahap (Multi-stage Composer + Node/Vite)**: Dependensi PHP dan kompilasi aset frontend (`npm run build`) dilakukan otomatis saat pembuatan image Docker, sedangkan runtime memakai `php:8.3-fpm-alpine` yang ringan dan aman.
- **Migrasi & Seeding Awal Otomatis**: Saat container pertama kali menyala di server baru (tabel `users` masih kosong), sistem otomatis menjalankan `php artisan migrate --force` dan `php artisan db:seed --force`.
- **Tanpa Rahasia di Image**: Tidak ada password/kredensial yang tertanam di Docker image. Seluruh variabel rahasia dimuat saat runtime dari file `.env` di server.
- **CI/CD Otomatis**: Menjalankan unit test, audit celah keamanan (`composer audit`), serta mem-build dan mengunggah image ke `ghcr.io`.

---

## 1. Struktur Direktori Proyek

```text
proyek-laravel-anda/
├── Dockerfile                  # Petunjuk build multi-stage Docker (Composer + Node + PHP-FPM)
├── .dockerignore               # Daftar pengecualian file saat proses docker build
├── .gitignore                  # Mencegah file .env dan vendor ikut ter-commit ke Git
├── .gitattributes              # Menjaga format baris LF pada skrip Linux (.sh)
├── compose.yaml                # Konfigurasi container runtime (app, web, db)
├── compose.build.yaml          # Override untuk build lokal di komputer developer
├── .env.docker.example         # Contoh variabel environment runtime Docker
├── docker/
│   ├── nginx.conf              # Konfigurasi web server internal Nginx (termasuk static assets)
│   ├── php.ini                 # Konfigurasi runtime PHP-FPM & OPcache
│   └── entrypoint.sh           # Skrip sinkronisasi aset, cache, migrasi, & auto-seed awal
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
  4. **Penting untuk Migrasi & Seeder**: Pastikan seluruh migrasi dan seeder Anda berjalan bersih pada database kosong (`php artisan migrate:fresh --seed`), karena container Docker akan membuat database baru dari nol.

---

## 3. Aturan Penting Pengisian `.env.docker.example` & `compose.yaml`

### A. Aturan File `.env.docker.example`:
1. **Biarkan Default Produksi**:
   Tetap biarkan nilai berikut di `.env.docker.example`:
   ```env
   APP_ENV=production
   APP_KEY=base64:ISI_DI_ENV_LOKAL_DAN_SERVER
   APP_DEBUG=false
   APP_URL=https://nama-aplikasi.landakkab.go.id
   ```
   - `APP_URL` langsung diisi dengan alamat **subdomain produksi resmi** (bukan alamat `-dev`). Penyesuaian domain `-dev` di VM Development akan diatur langsung oleh GitOps Administrator di file `.env` server.
2. **Aturan Koneksi Database Docker**:
   - **`DB_HOST=db`**: Wajib diisi `db` (nama service container MySQL), **jangan** diisi `127.0.0.1` atau `localhost`.
   - **`DB_USERNAME=nama_db_user`**: Wajib menggunakan nama user biasa, **dilarang keras mengisi `root`**! Container resmi MySQL 8.4 akan menolak menyala (*error*) jika `MYSQL_USER` diisi `root`.
3. **Jangan Taruh Rahasia Asli**:
   Seluruh variabel kustom aplikasi Anda wajib dicantumkan di `.env.docker.example` dengan **nilai dummy/contoh**. Serahkan nilai rahasia asli ke GitOps Administrator melalui jalur komunikasi privat.
4. **Gunakan Path Linux**:
   Jika aplikasi menyimpan file/backup ke path tertentu, gunakan path Linux di dalam container (misal `/var/www/html/storage/backups`), jangan gunakan huruf drive Windows (`D:/...`).

### B. Empat Bagian yang Wajib Disesuaikan di `compose.yaml`:
Buka file `compose.yaml` di root proyek Anda, lalu sesuaikan **4 bagian** berpenanda `[EDIT 1/4]` s.d. `[EDIT 4/4]`:

| Penanda | Baris di `compose.yaml` | Contoh Penggantian | Penjelasan |
|---|---|---|---|
| **`[EDIT 1/4]`** | `name: nama-aplikasi` | `name: finda` | Nama proyek Docker Compose (wajib sama dengan nama repo). |
| **`[EDIT 2/4]`** | `image: ghcr.io/diskominfo-landak/nama-aplikasi:${IMAGE_TAG:-development}` | `image: ghcr.io/diskominfo-landak/finda:${IMAGE_TAG:-development}` | Sesuaikan `nama-aplikasi` dengan nama repositori GitHub Anda (huruf kecil). |
| **`[EDIT 3/4]`** | Blok `ports:` pada service `web` | `"127.0.0.1:8081:80"` *(Web UI)* **atau** hapus blok `ports:` *(API Service)* | Lihat penjelasan **Opsi Port** di bawah. Nomor port **tidak perlu diganti** saat merge PR dari `development` ke `main`. |
| **`[EDIT 4/4]`** | `aliases:` di bawah `networks.api-net` | `- finda-web` | Nama panggilan internal container di jaringan Docker `api-net`. |

#### Penjelasan Khusus `[EDIT 3/4]` (Pilihan Port Web UI vs API Service):
1. **Jika Aplikasi Web Pengguna (Human-facing, memiliki halaman login/UI)**:
   - Pertahankan blok `ports: - "127.0.0.1:8081:80"`.
   - Saat diuji di laptop lokal, Anda bebas menggunakan port berapa saja yang kosong (misal `8081`).
   - Saat akan dipasang ke Server VM, **koordinasikan nomor port tersebut 1 kali di awal dengan GitOps / Network Administrator** agar tidak bentrok dengan aplikasi OPD lain. Nomor port ini tetap sama untuk branch `development` maupun `main`.
2. **Jika Layanan API Internal (Machine-to-Machine di belakang `api-gateway`)**:
   - **Hapus** atau beri tanda komentar (`#`) pada baris `ports:` dan `- "127.0.0.1:8081:80"`, sehingga layanan API hanya dapat diakses dari dalam jaringan `api-net` via alias (`http://nama-aplikasi-web`).

---

## 4. Pengujian & Publikasi (Pilih Sesuai Spesifikasi Laptop Anda)

Tidak semua komputer pengembang memiliki spesifikasi RAM/CPU yang memadai untuk menjalankan Docker. Pilih **salah satu jalur** di bawah ini:

### Jalur A: Laptop Tanpa Docker (Langsung Push ke GitHub)

Jika komputer Anda belum terpasang Docker (hanya menggunakan Laragon / XAMPP):

1. **Langkah 1 — Minta Nama Repositori & Hak Akses ke Admin GitOps**:
   - Sampaikan username akun GitHub Anda kepada **Admin GitOps**.
   - Admin GitOps akan membuatkan repositori resmi di `https://github.com/Diskominfo-Landak/<nama-repo>` sesuai nama subdomain yang disepakati (misal: `simpeg`, `finda`), serta menambahkan akun Anda sebagai kolaborator.
   - Minta juga alokasi **nomor port upstream** internal (misal: `8081`) untuk diisi pada penanda `[EDIT 3/4]` di `compose.yaml`.

2. **Langkah 2 — Pastikan Aplikasi Lokal Siap**:
   - Pastikan aplikasi di folder `src/` berjalan normal di Laragon/XAMPP.
   - Pastikan migrasi dan seeder bersih dari nol:
     ```bash
     cd src
     php artisan migrate:fresh --seed
     php artisan test
     cd ..
     ```
   - Pastikan ke-4 titik `[EDIT 1/4]` s.d. `[EDIT 4/4]` di `compose.yaml` dan variabel di `.env.docker.example` sudah disesuaikan dengan `<nama-repo>`.

3. **Langkah 3 — Tutorial Inisialisasi Git Remote & Push Pertama Kali**:
   Ikuti langkah berikut agar tidak bingung saat pertama kali menghubungkan laptop ke repositori GitHub organisasi:
   ```bash
   # 1. Buka terminal di root direktori proyek (bukan di dalam folder src/)
   cd /path/ke/proyek-laravel   # misal: cd C:\laragon\www\finda

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
   git commit -m "feat: inisialisasi proyek laravel dengan template gitops"

   # 7. Push PERDANA ke branch development dengan flag '-u' (upstream):
   git push -u origin development
   ```
   > 💡 **Catatan Flag `-u` (`--set-upstream`)**:
   > Perintah `git push -u origin development` hanya dijalankan **1 kali di awal** untuk mengaitkan branch lokal ke GitHub. Untuk push fitur harian berikutnya, Anda cukup mengetik:
   > ```bash
   > git push
   > ```

4. **Langkah 4 — Pantau CI/CD GitHub Actions**:
   Buka tab **Actions** di repositori GitHub Anda. GitHub Actions akan otomatis menguji kode, mem-build Docker image (`ghcr.io/diskominfo-landak/<nama-repo>:development`), dan Server VM Development akan otomatis men-deploy container ke `https://<nama-repo>-dev.landakkab.go.id`!

---

### Jalur B: Uji Coba Container di Komputer Lokal (Jika Memiliki Docker)

> **Belum punya Docker di laptop?**
> - **Windows**: Instal [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/) (memerlukan fitur WSL 2 aktif) dan pastikan aplikasi Docker Desktop sudah dinyalakan hingga berstatus *Engine running*.
> - **WSL 2 (Ubuntu)**: Jika Docker Engine Anda terpasang langsung di dalam distro Ubuntu WSL 2 (bukan Docker Desktop di Windows), **jalankan seluruh perintah di bawah ini dari dalam terminal Ubuntu WSL** dengan berpindah ke folder proyek terlebih dahulu:
>   ```bash
>   cd /mnt/c/laragon/www/nama-proyek-anda
>   ```

#### 1. Buat Jaringan Eksternal `api-net` & Salin File `.env`
Pilih perintah sesuai terminal yang Anda gunakan:

**Opsi Terminal Linux / macOS / WSL 2 (Ubuntu):**
```bash
# 1. Buat jaringan api-net (cukup 1 kali; abaikan jika muncul pesan 'already exists')
docker network create api-net 2>/dev/null || true

# 2. Salin template environment menjadi .env runtime Docker di root proyek
cp .env.docker.example .env
```

**Opsi Terminal Windows PowerShell:**
```powershell
# 1. Buat jaringan api-net (cukup 1 kali; abaikan jika muncul pesan 'already exists')
docker network create api-net

# 2. Salin template environment menjadi .env runtime Docker di root proyek
Copy-Item .env.docker.example .env
```

#### 2. Sesuaikan Isi File `.env` Lokal
Buka file `.env` yang baru dibuat di root proyek:
- Isi `APP_KEY=base64:...` (bisa disalin dari `src/.env` lokal Anda).
- Pastikan `DB_HOST=db` dan `DB_USERNAME` **bukan** `root` (misal: `DB_USERNAME=finda_user`).
- Isi kredensial lain yang dibutuhkan aplikasi (seperti password Superadmin untuk seeder).

#### 3. Build dan Jalankan Container
```bash
docker compose -f compose.yaml -f compose.build.yaml up -d --build
```

#### 4. Periksa Kesehatan Container & Log
```bash
docker compose ps
docker compose logs -f app
```
> **Tips Troubleshooting Lokal**:
> - Pastikan ketiga container (`db`, `app`, `web`) berstatus **`Up (healthy)`**.
> - Jika `db` gagal menyala, cek log dengan `docker compose logs db`.
> - Jika ingin mengulang pengujian database benar-benar dari nol (menghapus volume database lokal), jalankan `docker compose down -v` lalu ulangi langkah 3.

Jika aplikasi Web UI dibuka di port `8081`, uji melalui browser di `http://localhost:8081` dan pastikan `http://localhost:8081/up` menampilkan status sehat (HTTP 200).
