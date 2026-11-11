# Panduan Praktis untuk Developer (Pengembang Aplikasi)

Panduan ini ditujukan bagi programmer/developer di lingkungan Diskominfo Pemkab Landak untuk menyiapkan struktur proyek berbasis template GitOps, menguji di komputer lokal, dan mempublikasikan perubahan ke GitHub.

---

## 1. Alur Memulai Proyek Aplikasi Baru

Sesuai *Juknis Pedoman Pembangunan dan Pengembangan Aplikasi Pemkab Landak*, developer **tidak perlu membuat repositori sendiri**:

1. **GitOps Administrator** akan membuatkan repositori resmi di bawah organisasi `diskominfo-landak`. Nama repositori disesuaikan dengan nama subdomain produksi yang direncanakan (misal: `simpeg` atau `finda`).
2. GitOps Administrator akan meminta username akun GitHub Anda dan memasukkannya sebagai kontributor (`Write`) pada repositori tersebut.
3. Anda cukup melakukan `git clone` repositori tersebut ke laptop Anda, lalu menyalin berkas template GitOps dari repositori `Petunjuk-GitOps`:
   - **Laravel (PHP 8.3 + MySQL 8.4 + Vite)**: Salin isi [`template/laravel/`](../template/laravel/)
   - **CodeIgniter (CI 4 / CI 3)**: Salin isi [`template/codeigniter/`](../template/codeigniter/)
   - **Node.js (Express / Fastify / API / SSR)**: Salin isi [`template/nodejs/`](../template/nodejs/)
   - **PHP Native / Legacy**: Salin isi [`template/php-native/`](../template/php-native/)

### Struktur Folder:
Seluruh file infrastruktur (`Dockerfile`, `compose.yaml`, `.github/`, dll.) berada di **root proyek**, sedangkan seluruh kodingan aplikasi Anda diletakkan di dalam **folder `src/`**:
```text
repositori-aplikasi-anda/
├── Dockerfile                  # Konfigurasi build image Docker (Composer + Node + PHP-FPM)
├── .dockerignore               # Pengecualian file saat proses build
├── .gitignore                  # Mencegah file .env dan vendor ikut ter-commit
├── .gitattributes              # Menjaga line-ending LF pada skrip Linux
├── compose.yaml                # Konfigurasi container runtime (app, web, db)
├── compose.build.yaml          # Override untuk build lokal di laptop
├── .env.docker.example         # Template variabel environment runtime Docker
├── docker/                     # Konfigurasi Nginx, PHP-FPM, dan entrypoint
├── .github/workflows/ci.yml    # Pipeline otomatis GitHub Actions ke GHCR
└── src/                        # << TEMPAT SELURUH KODE APLIKASI ANDA >>
```

---

## 2. Tanggung Jawab Database, Seeder, & Pengelolaan Variabel `.env`

Di lingkungan GitOps, developer **tidak diberikan akses SSH langsung ke server VM**. Seluruh perubahan struktur database dan konfigurasi harus disampaikan melalui repositori Git dan koordinasi aman dengan GitOps Administrator:

### A. Seluruh Perubahan Database Wajib Menggunakan Migration & Seeder Bersih
- **Dilarang keras** mengubah tabel atau kolom secara manual di database server.
- Buat file migrasi untuk setiap tabel atau kolom baru:
  - Laravel: `php artisan make:migration create_tabel_baru`
  - CodeIgniter 4: `php spark make:migration CreateTabelBaru`
- **Eksekusi Otomatis di Server (Zero-Touch)**:
  - Saat container menyala di server, skrip `entrypoint.sh` **secara otomatis menjalankan migrasi** (`php artisan migrate --force`).
  - Khusus pada **deploy perdana** (ketika tabel `users` terdeteksi masih kosong / `0` baris), sistem **secara otomatis menjalankan seeder awal** (`php artisan db:seed --force`). Pada update berikutnya, seeder otomatis dilewati agar tidak menimpa data pengguna.
- **Pastikan Migrasi & Seeder Lolos dari Database Kosong**:
  Sebelum mem-push kode ke GitHub, pastikan perintah `php artisan migrate:fresh --seed` di komputer Anda berjalan mulus tanpa error (jangan bergantung pada tabel warisan yang tidak ada file migrasinya, dan pastikan semua kolom `NOT NULL` seperti UUID `public_id` sudah terisi di seeder).

### B. Aturan Pengisian `.env.docker.example` vs `.env` Lokal Developer
1. **Biarkan Pengaturan Produksi Default di `.env.docker.example`**:
   ```env
   APP_NAME=FINDA
   APP_ENV=production
   APP_KEY=base64:ISI_DI_ENV_LOKAL_DAN_SERVER
   APP_DEBUG=false
   APP_URL=https://finda.landakkab.go.id
   ```
   - Tetap biarkan `APP_ENV=production` dan `APP_DEBUG=false`.
   - Untuk `APP_URL`, **langsung isi dengan alamat subdomain produksi resmi** (bukan alamat `-dev`). Penyesuaian domain `-dev` di VM Development akan diatur oleh GitOps Administrator langsung pada file `.env` fisik di server VM Dev (dan tidak akan tertimpa saat `git pull`).
2. **Aturan Koneksi Database Docker (`DB_HOST` & `DB_USERNAME`)**:
   - **`DB_HOST=db`**: Di dalam Docker Compose, antarkontainer berkomunikasi menggunakan nama service. Wajib isi `DB_HOST=db`, **jangan** isi `127.0.0.1` atau `localhost`.
   - **`DB_USERNAME=nama_db_user`**: Wajib menggunakan nama user biasa (misal: `finda_user` atau `db_user`). **DILARANG KERAS mengisi `DB_USERNAME=root`**, karena image resmi MySQL 8.4 akan langsung menolak menyala (*crash*) jika `MYSQL_USER` diisi `root`.
3. **Nama Variabel Wajib Sama & Nilai Wajib Dummy**:
   - Seluruh variabel kustom yang digunakan aplikasi di kodingan Anda (misal `PENINK_STATS_API_KEY`, `FINDA_SUPERADMIN_PASSWORD`) **wajib dicantumkan namanya di `.env.docker.example`**.
   - **JANGAN PERNAH** menaruh password asli, token, atau API key rahasia di `.env.docker.example` karena file ini ter-commit ke Git. Gunakan nilai contoh/dummy (misal: `PENINK_STATS_API_KEY=masukkan_api_key_disini`).
4. **Gunakan Format Path Linux**:
   - Container Docker berjalan di atas Linux. Jika aplikasi menyimpan backup atau arsip log ke folder tertentu, gunakan path Linux (misal `/var/www/html/storage/backups`), **jangan** gunakan path drive Windows (`D:/...`).

### C. Cara Menyerahkan Kredensial Sensitif (API Key / Password) ke GitOps Administrator
1. **Dilarang Keras** menaruh data rahasia di Git commit, issue, atau Pull Request.
2. Serahkan nilai rahasia tersebut kepada **GitOps Administrator** melalui **jalur komunikasi privat yang aman** (misal: pesan langsung terenkripsi / bertatap muka).
3. GitOps Administrator yang akan memasukkan nilai rahasia tersebut ke dalam file `/opt/apps/<nama-aplikasi>/.env` di server fisik saat inisialisasi proyek.

---

## 3. Empat Bagian yang Wajib Disesuaikan di `compose.yaml`

Buka file `compose.yaml` di root proyek Anda, lalu sesuaikan **4 titik konfigurasi** yang ditandai dengan `[EDIT 1/4]` sampai `[EDIT 4/4]`:

| Penanda | Bagian di `compose.yaml` | Contoh Penggantian | Aturan & Penjelasan |
|---|---|---|---|
| **`[EDIT 1/4]`** | `name: nama-aplikasi` | `name: finda` | Nama stack Docker Compose (wajib sama dengan nama repositori Anda). |
| **`[EDIT 2/4]`** | `image: ghcr.io/diskominfo-landak/nama-aplikasi:${IMAGE_TAG:-development}` | `image: ghcr.io/diskominfo-landak/finda:${IMAGE_TAG:-development}` | Wajib sama persis dengan nama repositori GitHub di organisasi `diskominfo-landak`. |
| **`[EDIT 3/4]`** | Blok `ports:` pada service `web` | `"127.0.0.1:8081:80"` *(Web UI)* **atau** hapus blok `ports:` *(API Service)* | Lihat panduan pemilihan port di bawah. |
| **`[EDIT 4/4]`** | `aliases:` di bawah `networks.api-net` | `- finda-web` | Nama domain internal di jaringan Docker `api-net` (`<nama-repo>-web`). |

### Panduan Khusus Pemilihan Port (`[EDIT 3/4]`):
1. **Aplikasi Web Pengguna (Human-facing, memiliki antarmuka login/UI)**:
   - Gunakan format mapping port lokal:
     ```yaml
     ports:
       - "127.0.0.1:8081:80"
     ```
   - **PENTING TENTANG IP `127.0.0.1`**: 
     - **TETAP GUNAKAN `127.0.0.1`**, **JANGAN PERNAH** diubah menjadi IP publik VM!
     - `127.0.0.1` artinya container hanya mengizinkan koneksi lokal dari Reverse Proxy (Nginx utama VM) di server yang sama. Pengunjung dari internet luar tetap mengakses lewat domain resmi HTTPS port 443 yang aman.
   - **PENTING TENTANG NOMOR PORT (misal `8081`)**:
     - Di laptop lokal pengembang, Anda bebas memakai nomor port berapa saja yang kosong.
     - Untuk server VM, **tanyakan/minta alokasi nomor port resmi 1 kali di awal kepada GitOps Administrator** (contoh: FINDA dapat port `8081`, SIMPEG dapat port `8082`).
     - **Apakah port ini perlu diganti saat merge PR dari `development` ke `main`?** **TIDAK PERLU.** Karena VM Development dan VM Production adalah dua server yang terpisah, nomor port di `compose.yaml` dibuat **sama persis (identik)** antara branch `development` dan `main`.
2. **Layanan API Internal (Machine-to-Machine di belakang `api-gateway`)**:
   - **Hapus** atau beri tanda komentar (`#`) pada blok `ports:` agar layanan hanya bisa dijangkau oleh `api-gateway` dari dalam jaringan Docker `api-net` melalui nama alias (`http://nama-aplikasi-web`).

---

## 4. Pengujian & Publikasi (Pilih Sesuai Spesifikasi Komputer Anda)

Tidak semua laptop pengembang memiliki kapasitas RAM/CPU untuk menginstal Docker. Anda dapat memilih **Jalur A (Tanpa Docker)** atau **Jalur B (Dengan Docker)**:

### Jalur A: Laptop Tanpa Docker (Langsung Push ke GitHub)

Jika komputer Anda belum terpasang Docker (hanya menggunakan Laragon / XAMPP):
1. **Langkah 1 — Minta Nama Repositori & Hak Akses ke Admin GitOps**:
   - Sampaikan username akun GitHub Anda kepada **Admin GitOps**.
   - Admin GitOps akan membuatkan repositori resmi di organisasi `https://github.com/Diskominfo-Landak/<nama-repo>` sesuai nama subdomain yang disepakati (misal: `simpeg`, `finda`), serta menambahkan akun Anda sebagai kolaborator.
   - Tanyakan juga kepada Admin GitOps alokasi **nomor port upstream** internal (misal: `8081`) untuk diisikan pada penanda `[EDIT 3/4]` di `compose.yaml`.
2. **Langkah 2 — Pastikan Aplikasi Lokal Siap**:
   - Pastikan aplikasi di dalam folder `src/` sudah berjalan baik di Laragon/XAMPP.
   - Pastikan migrasi dari nol, seeder, dan unit test lulus:
     ```bash
     cd src
     php artisan migrate:fresh --seed
     php artisan test
     cd ..
     ```
   - Pastikan ke-4 titik `[EDIT 1/4]` s.d. `[EDIT 4/4]` di `compose.yaml` dan variabel di `.env.docker.example` sudah disesuaikan dengan `<nama-repo>` dari Admin GitOps.
3. **Langkah 3 — Tutorial Inisialisasi Git Remote & Push Pertama Kali**:
   Agar tidak bingung menghubungkan proyek laptop Anda ke repositori GitHub organisasi:
   ```bash
   # 1. Buka terminal di folder root proyek (bukan di dalam folder src/)
   cd /path/ke/folder-proyek-anda   # misal: cd C:\laragon\www\simpeg

   # 2. Inisialisasi git lokal jika belum ada folder .git
   git init

   # 3. Pindahkan / buat branch default bernama 'development'
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

   # 6. Tambahkan semua file dan buat commit perdana:
   git add .
   git commit -m "feat: inisialisasi proyek dan konfigurasi template gitops"

   # 7. Push PERDANA ke branch development dengan flag '-u' (upstream):
   git push -u origin development
   ```
   > 💡 **Tips Flag `-u` (`--set-upstream`)**:
   > Perintah `git push -u origin development` hanya perlu dijalankan **1 kali di awal**. Flag ini menghubungkan branch lokal dengan branch remote. Untuk push harian berikutnya, Anda cukup mengetik perintah singkat:
   > ```bash
   > git push
   > ```
4. **Langkah 4 — Pantau CI/CD GitHub Actions**:
   Setelah push berhasil, buka tab **Actions** di repositori GitHub Anda. Pipeline cloud akan otomatis menguji kode, mem-build Docker image (`ghcr.io/diskominfo-landak/<nama-repo>:development`), dan server VM Development akan otomatis menjalankan aplikasi Anda di domain uji `https://<nama-repo>-dev.landakkab.go.id`!

---

### Jalur B: Uji Coba Container di Komputer Lokal (Jika Memiliki Docker)

#### Prasyarat Instalasi Docker (Jika Belum Ada):
- **Pengguna Windows**: Unduh dan instal [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/) (pastikan fitur WSL 2 aktif). Setelah terinstal, buka aplikasi **Docker Desktop** dari Start Menu dan tunggu hingga berstatus *Engine running* sebelum menjalankan perintah di terminal.
- **Pengguna Docker di Dalam WSL 2 (Ubuntu)**: Jika Docker Engine Anda terpasang langsung di dalam distro Ubuntu WSL 2 (sehingga perintah `docker` tidak dikenali di PowerShell Windows), **buka terminal Ubuntu (WSL)** dan masuk ke direktori proyek Windows Anda melalui `/mnt/c/`:
  ```bash
  cd /mnt/c/laragon/www/nama-proyek-anda
  ```

#### Langkah-Langkah Eksekusi:

**1. Buat jaringan Docker `api-net` & siapkan file `.env` runtime Docker:**

*Jika menggunakan Terminal Linux / macOS / WSL 2 (Ubuntu):*
```bash
# Buat jaringan Docker 'api-net' (cukup 1 kali; abaikan jika muncul 'already exists')
docker network create api-net 2>/dev/null || true

# Salin template menjadi file .env runtime Docker di root proyek
cp .env.docker.example .env
```

*Jika menggunakan Terminal Windows PowerShell:*
```powershell
# Buat jaringan Docker 'api-net' (cukup 1 kali; abaikan jika muncul 'already exists')
docker network create api-net

# Salin template menjadi file .env runtime Docker di root proyek
Copy-Item .env.docker.example .env
```

**2. Sesuaikan isi file `.env` lokal Anda:**
Buka file `.env` di root proyek:
- Isi `APP_KEY=base64:...` (bisa disalin dari `src/.env` lokal Anda).
- Pastikan `DB_HOST=db` dan `DB_USERNAME` **bukan** `root` (misal: `DB_USERNAME=finda_user`).
- Untuk kemudahan debugging di laptop sendiri, Anda boleh mengubah `APP_ENV=local` dan `APP_DEBUG=true` pada file `.env` lokal ini (file `.env` tidak akan ter-commit ke Git).

**3. Build dan jalankan container di lokal:**
```bash
docker compose -f compose.yaml -f compose.build.yaml up -d --build
```
*(Tahap ini akan mem-build Composer, mengompilasi aset frontend Vite `npm run build`, menyalakan MySQL, menjalankan migrasi, dan menjalankan seeder awal secara otomatis).*

**4. Periksa status kesehatan container & log aplikasi:**
```bash
docker compose ps
docker compose logs -f app
```
- Pastikan ketiga container (`db`, `app`, `web`) berstatus **`Up (healthy)`**.
- Buka di browser: `http://localhost:8081` (sesuai port di `compose.yaml`).
- Jika ada masalah pada database, cek dengan `docker compose logs db`.
- Jika ingin mereset database container lokal dari nol (menghapus volume), jalankan `docker compose down -v` lalu ulangi langkah 3.

---

## 5. Alur Kerja Git & Publikasi Fitur

### A. Alur Pengembangan Harian (Branch `development`)
1. Pastikan file `.env` lokal tidak ikut ter-commit (`git status`).
2. Commit dan push perubahan ke branch `development`:
   ```bash
   git checkout -b development # (atau 'git checkout development' jika branch sudah ada)
   git add .
   git commit -m "feat: tambah modul presensi"
   git push -u origin development
   ```
3. **GitHub Actions** secara otomatis akan:
   - Menjalankan unit test dan pemeriksaan keamanan paket (`composer audit`) di dalam folder `src/`.
   - Mem-build image Docker (termasuk kompilasi aset Vite/Tailwind) dan mengunggahnya ke `ghcr.io/diskominfo-landak/<nama-repo>:development`.
4. Maksimal dalam **5 menit**, server **VM Development** secara otomatis menarik image baru tersebut, menjalankan migrasi (serta seeder awal jika database baru), dan memperbarui aplikasi di domain uji `https://<nama-repo>-dev.landakkab.go.id`.

### B. Alur Pengajuan Rilis ke Produksi (Pull Request ke `main`)
Ketika fitur di VM Development sudah diuji dan dinyatakan stabil:
1. Buka repositori di GitHub, lalu buat **Pull Request (PR)** dari branch `development` menuju branch **`main`**. *(Anda tidak perlu mengubah nomor port di `compose.yaml` saat membuat PR ini).*
2. Berikan judul yang jelas (contoh: `Rilis Fitur Presensi v1.1.0`) dan tuliskan changelog perubahan serta informasi variabel baru di file `.env.docker.example` jika ada.
3. Informasikan kepada **GitOps Administrator** untuk dilakukan review manual dan persetujuan penggabungan (*merge*).
4. Setelah PR di-merge ke `main`, GitOps Administrator akan menerbitkan Tag Rilis SemVer resmi (`vX.Y.Z`), dan Network Administrator akan memasangnya ke VM Production.
