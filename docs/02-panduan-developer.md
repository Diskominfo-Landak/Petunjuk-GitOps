# Panduan Praktis untuk Developer (Pengembang Aplikasi)

Panduan ini ditujukan bagi programmer/developer di lingkungan Diskominfo Pemkab Landak untuk menyiapkan struktur proyek berbasis template GitOps, menguji di komputer lokal, dan mempublikasikan perubahan ke GitHub.

---

## 1. Alur Memulai Proyek Aplikasi Baru

Sesuai *Juknis Pedoman Pembangunan dan Pengembangan Aplikasi Pemkab Landak*, developer **tidak perlu membuat repositori sendiri**:

1. **GitOps Administrator** akan membuatkan repositori resmi di bawah organisasi `diskominfo-landak`. Nama repositori disesuaikan dengan nama subdomain produksi yang direncanakan (misal: `simpeg`).
2. GitOps Administrator akan meminta username akun GitHub Anda dan memasukkannya sebagai kontributor (`Write`) pada repositori tersebut.
3. Anda cukup melakukan `git clone` repositori tersebut ke laptop Anda, lalu menyalin berkas template GitOps dari repositori `Petunjuk-GitOps`:
   - **Laravel (PHP 8.3 + MySQL 8.4)**: Salin isi [`template/laravel/`](../template/laravel/)
   - **CodeIgniter (CI 4 / CI 3)**: Salin isi [`template/codeigniter/`](../template/codeigniter/)
   - **Node.js (Express / Fastify / API / SSR)**: Salin isi [`template/nodejs/`](../template/nodejs/)
   - **PHP Native / Legacy**: Salin isi [`template/php-native/`](../template/php-native/)

### Struktur Folder:
Seluruh file infrastruktur (`Dockerfile`, `compose.yaml`, `.github/`, dll.) berada di **root proyek**, sedangkan seluruh kodingan aplikasi Anda diletakkan di dalam **folder `src/`**:
```text
repositori-aplikasi-anda/
├── Dockerfile                  # Konfigurasi build image Docker
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

## 2. Tanggung Jawab Database & Pengelolaan Variabel `.env`

Di lingkungan GitOps, developer **tidak diberikan akses SSH langsung ke server VM**. Seluruh perubahan struktur database dan konfigurasi harus disampaikan melalui repositori Git dan koordinasi aman dengan GitOps Administrator:

### A. Seluruh Perubahan Database Wajib Menggunakan Migration
- **Dilarang keras** mengubah tabel atau kolom secara manual di database server.
- Buat file migrasi untuk setiap tabel atau kolom baru:
  - Laravel: `php artisan make:migration create_tabel_baru`
  - CodeIgniter 4: `php spark make:migration CreateTabelBaru`
- Saat aplikasi di-deploy ke server, sistem GitOps akan **secara otomatis menjalankan migrasi** (`migrate --force`) saat container menyala.

### B. Aturan `.env.docker.example` vs `.env` Lokal Developer
- **Nama Variabel Wajib Sama**: Seluruh variabel yang digunakan aplikasi di kodingan Anda (misal `PAYMENT_API_KEY`, `WA_GATEWAY_TOKEN`, `DEFAULT_ADMIN_PASSWORD`) **wajib dicantumkan namanya di file `.env.docker.example`**.
- **Nilai Wajib Menggunakan Nilai Contoh / Dummy**: 
  Di file `.env.docker.example`, nilainya adalah nilai contoh/dummy (misal: `PAYMENT_API_KEY=masukkan_api_key_disini`). **JANGAN PERNAH** menaruh password asli atau kredensial rahasia di file `.env.docker.example` karena file ini ter-commit ke Git.

### C. Cara Menyerahkan Kredensial Sensitif (API Key / Password) ke GitOps Administrator
Jika aplikasi Anda membutuhkan kredensial rahasia sungguhan (misal: production API Key, secret Keycloak, atau password akun Superadmin untuk seeder):
1. **Dilarang Keras** menaruh data rahasia di Git commit, issue, atau Pull Request.
2. Serahkan nilai rahasia tersebut kepada **GitOps Administrator** melalui **jalur komunikasi privat yang aman** (misal: pesan langsung terenkripsi / bertatap muka).
3. GitOps Administrator yang akan memasukkan nilai rahasia tersebut ke dalam file `/opt/apps/<nama-aplikasi>/.env` di server fisik saat proses deployment.

---

## 3. Empat Bagian yang Wajib Disesuaikan di `compose.yaml`

Buka file `compose.yaml` di root proyek Anda, lalu sesuaikan **4 titik konfigurasi** yang ditandai dengan `[EDIT 1/4]` sampai `[EDIT 4/4]`:

| Penanda | Bagian di `compose.yaml` | Contoh Penggantian | Aturan & Penjelasan |
|---|---|---|---|
| **`[EDIT 1/4]`** | `name: nama-aplikasi` | `name: simpeg` | Nama stack Docker Compose (wajib sama dengan nama repositori Anda). |
| **`[EDIT 2/4]`** | `image: ghcr.io/diskominfo-landak/nama-aplikasi:${IMAGE_TAG:-development}` | `image: ghcr.io/diskominfo-landak/simpeg:${IMAGE_TAG:-development}` | Wajib sama persis dengan nama repositori GitHub di organisasi `diskominfo-landak`. |
| **`[EDIT 3/4]`** | Blok `ports:` pada service `web` | `"127.0.0.1:8081:80"` *(Web UI)* **atau** hapus blok `ports:` *(API Service)* | Lihat panduan pemilihan port di bawah. |
| **`[EDIT 4/4]`** | `aliases:` di bawah `networks.api-net` | `- simpeg-web` | Nama domain internal di jaringan Docker `api-net` (`<nama-repo>-web`). |

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
     - Namun di server VM, nomor port tidak boleh tabrakan antar aplikasi. **Tanyakan/minta alokasi nomor port server resmi kepada GitOps Administrator** (contoh: FINDA dapat port `8081`, SIMPEG dapat port `8082`, dst.).
2. **Layanan API Internal (Machine-to-Machine di belakang `api-gateway`)**:
   - **Hapus** atau beri tanda komentar (`#`) pada blok `ports:`:
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
   - Layanan Anda akan terlindung di dalam jaringan kabel Docker `api-net` dan hanya bisa dijangkau oleh `api-gateway` via nama alias (`http://nama-aplikasi-web`).

---

## 4. Menjalankan & Menguji Aplikasi di Komputer Lokal

Sebelum mendorong kode ke GitHub, uji container di laptop Anda menggunakan `compose.build.yaml`:

```bash
# 1. Buat jaringan Docker 'api-net' (cukup 1 kali di laptop Anda):
docker network create api-net 2>/dev/null || true

# 2. Buat file .env runtime Docker di root proyek dari template:
cp .env.docker.example .env
# (Khusus Laravel: pastikan APP_KEY di .env sudah terisi, misal base64:...)

# 3. Build dan jalankan container di lokal:
docker compose -f compose.yaml -f compose.build.yaml up -d --build

# 4. Periksa status kesehatan container & log aplikasi:
docker compose ps
docker compose logs -f app

# 5. Mengakses shell container PHP (untuk menjalankan artisan / spark / debug):
docker compose exec app sh

# 6. Menghentikan container:
docker compose down
```

---

## 5. Alur Kerja Git & Publikasi Fitur

### A. Alur Pengembangan Harian (Branch `development`)
1. Kembangkan fitur di laptop dan pastikan pengujian lokal lulus.
2. Commit dan push perubahan ke branch `development`:
   ```bash
   git checkout development
   git add .
   git commit -m "feat: tambah modul presensi"
   git push origin development
   ```
3. **GitHub Actions** secara otomatis akan:
   - Menjalankan unit test dan pemeriksaan keamanan paket (`composer audit`) di dalam folder `src/`.
   - Mem-build image Docker dan mengunggahnya ke `ghcr.io/diskominfo-landak/<nama-repo>:development`.
4. Maksimal dalam **5 menit**, server **VM Development** secara otomatis menarik image baru tersebut dan memperbarui aplikasi di domain uji `https://<nama-repo>-dev.landakkab.go.id`.

### B. Alur Pengajuan Rilis ke Produksi (Pull Request ke `main`)
Ketika fitur di VM Development sudah diuji dan dinyatakan stabil:
1. Buka repositori di GitHub, lalu buat **Pull Request (PR)** dari branch `development` menuju branch **`main`**.
2. Berikan judul yang jelas (contoh: `Rilis Fitur Presensi v1.1.0`) dan tuliskan changelog perubahan serta informasi variabel baru di file `.env.docker.example` jika ada.
3. Informasikan kepada **GitOps Administrator** untuk dilakukan review manual dan persetujuan penggabungan (*merge*).
4. Setelah PR di-merge ke `main`, GitOps Administrator akan menerbitkan Tag Rilis SemVer resmi (`vX.Y.Z`), dan Network Administrator akan memasangnya ke VM Production.
