# Panduan Praktis untuk Developer (Pengembang Aplikasi)

Panduan ini ditujukan bagi programmer/developer di lingkungan Diskominfo Pemkab Landak untuk menyiapkan struktur proyek berbasis template GitOps, menguji di komputer lokal, dan mempublikasikan perubahan ke GitHub.

---

## 1. Struktur Proyek & Penggunaan Folder `src/`

Pada standar GitOps Pemkab Landak, berkas infrastruktur kontainerisasi (Docker & CI/CD) berada di **root repositori**, sedangkan seluruh kode sumber aplikasi Anda diletakkan di dalam **folder `src/`**:

```text
repositori-aplikasi-anda/
├── Dockerfile                  # Konfigurasi build image Docker (membaca kode dari src/)
├── .dockerignore               # Pengecualian file saat proses docker build
├── .gitignore                  # Mencegah file .env dan vendor ikut ter-commit
├── .gitattributes              # Menjaga line-ending LF pada skrip Linux
├── compose.yaml                # Konfigurasi layanan container (app, web, db)
├── compose.build.yaml          # Override untuk build lokal di laptop developer
├── .env.docker.example         # Template variabel environment runtime Docker
├── docker/                     # Konfigurasi Nginx, PHP-FPM, dan entrypoint
├── .github/workflows/ci.yml    # Pipeline otomatis GitHub Actions ke GHCR
└── src/                        # << TEMPAT KODE SUMBER APLIKASI ANDA >>
```

Pilih template yang sesuai dengan framework aplikasi Anda:
- **Laravel (PHP 8.3 + MySQL 8.4)**: [`template/laravel/`](../template/laravel/)
- **CodeIgniter (CI 4 / CI 3)**: [`template/codeigniter/`](../template/codeigniter/)

### Cara Memulai:
1. Salin seluruh isi folder template pilihan Anda (`template/laravel/` atau `template/codeigniter/`, termasuk file tersembunyi `.gitignore`, `.dockerignore`, `.gitattributes`, `.env.docker.example`, dan `.github/`) ke dalam repositori proyek Anda.
2. **Jika membuat aplikasi baru dari nol**: Anda bisa langsung mulai mengedit kode di dalam folder `src/` (sudah berisi kerangka proyek murni Laravel atau CodeIgniter 4).
3. **Jika memigrasikan aplikasi yang sudah ada**: Hapus isi bawaan di dalam folder `src/`, lalu pindahkan seluruh file kode aplikasi Anda ke dalam folder `src/`.

---

## 2. Empat Bagian yang Wajib Disesuaikan di `compose.yaml`

Buka file `compose.yaml` di root proyek Anda, lalu sesuaikan **4 titik konfigurasi** yang ditandai dengan `[EDIT 1/4]` sampai `[EDIT 4/4]`:

| Penanda | Bagian di `compose.yaml` | Contoh Penggantian | Aturan & Penjelasan |
|---|---|---|---|
| **`[EDIT 1/4]`** | `name: nama-aplikasi` | `name: finda-app` | Nama stack Docker Compose (gunakan nama repositori Anda, huruf kecil). |
| **`[EDIT 2/4]`** | `image: ghcr.io/diskominfo-landak/nama-aplikasi:${IMAGE_TAG:-development}` | `image: ghcr.io/diskominfo-landak/finda-app:${IMAGE_TAG:-development}` | Wajib sama persis dengan nama repositori GitHub di organisasi `diskominfo-landak`. |
| **`[EDIT 3/4]`** | Blok `ports:` pada service `web` | `"127.0.0.1:8081:80"` *(Web UI)* **atau** hapus blok `ports:` *(API Service)* | Lihat panduan pemilihan port di bawah. |
| **`[EDIT 4/4]`** | `aliases:` di bawah `networks.api-net` | `- finda-app-web` | Nama domain internal di jaringan Docker `api-net` (`<nama-repo>-web`). |

### Panduan Pemilihan Port (`[EDIT 3/4]`):
1. **Aplikasi Web Pengguna (Human-facing, diakses via browser)**:
   - Gunakan mapping port lokal:
     ```yaml
     ports:
       - "127.0.0.1:8081:80"
     ```
   - **Penting**: Nomor port di server VM (misal `8081`, `8082`, dst.) **ditentukan oleh Admin Infrastruktur (Network Administrator)** agar tidak bentrok antar aplikasi di server dan agar didaftarkan ke Reverse Proxy domain resmi `.landakkab.go.id`.
2. **Layanan API Internal (Machine-to-Machine di belakang `api-gateway`)**:
   - **Hapus** atau beri tanda komentar (`#`) pada blok `ports:` sehingga port container tidak terbuka ke host:
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
   - Layanan Anda akan dipanggil oleh `api-gateway` secara internal melalui jaringan `api-net` menggunakan nama alias (`http://nama-aplikasi-web`).

---

## 3. Menjalankan & Menguji Aplikasi di Komputer Lokal

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

# 5. Mengakses shell container PHP (untuk menjalankan artisan / migrasi / debug):
docker compose exec app sh

# 6. Menghentikan container:
docker compose down
```

---

## 4. Alur Kerja Git & Publikasi Fitur

### A. Alur Pengembangan Harian (Branch `development`)
1. Kembangkan fitur dan pastikan unit test lulus di lokal.
2. Commit dan push perubahan ke branch `development`:
   ```bash
   git checkout development
   git add .
   git commit -m "feat: tambah fitur laporan bulanan"
   git push origin development
   ```
3. **GitHub Actions** secara otomatis akan:
   - Menjalankan unit test dan pemeriksaan keamanan paket (`composer audit`) di dalam folder `src/`.
   - Mem-build image Docker dan mengunggahnya ke `ghcr.io/diskominfo-landak/<nama-repo>:development`.
4. Maksimal dalam **5 menit**, cron di **VM Development** akan menarik image baru tersebut dan memperbarui layanan secara otomatis.

### B. Alur Pengajuan Rilis ke Produksi (Pull Request ke `main`)
1. Setelah fitur teruji dan stabil di VM Development, buat **Pull Request (PR)** di GitHub dari branch `development` menuju branch `main`.
2. Sertakan ringkasan perubahan dan catatan migrasi/konfigurasi baru (jika ada) pada deskripsi PR.
3. **Lead Developer / Admin Organisasi** akan me-review PR, melakukan merge ke `main`, dan menerbitkan **Tag Rilis SemVer** resmi (`vX.Y.Z`, contoh: `v1.0.1`).
4. Setelah GitHub Actions selesai mem-build image bernomor (`1.0.1`), **Network Administrator** akan memasang versi tersebut ke VM Production menggunakan skrip `release.sh`.
