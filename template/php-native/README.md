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

## ⚙️ 4 Titik Edit di `compose.yaml` & `.env.docker.example`

Sebelum push ke repositori GitHub, sesuaikan:
1. `[EDIT 1/4]` : Ganti nama proyek (`name: nama-aplikasi-php`).
2. `[EDIT 2/4]` : Sesuaikan nama image (`image: ghcr.io/diskominfo-landak/nama-aplikasi-php:${IMAGE_TAG:-development}`).
3. `[EDIT 3/4]` : Alokasikan port lokal (misal `"127.0.0.1:8084:80"`). Nomor port ini ditentukan 1 kali bersama Admin Infrastruktur dan **tidak perlu diubah** saat merge ke `main`.
4. `[EDIT 4/4]` : Sesuaikan alias jaringan Docker (`- nama-aplikasi-php-web`).

Di file `.env.docker.example`:
- Pastikan `DB_HOST=db` (jangan `127.0.0.1`) dan `DB_USERNAME` menggunakan nama user biasa (**dilarang mengisi `root`**).

---

## 🚀 Pengujian & Publikasi (Pilih Sesuai Spesifikasi Laptop)

### Jalur A: Laptop Tanpa Docker (Langsung Push ke GitHub)
Jika laptop Anda tidak memiliki Docker, pastikan aplikasi berjalan normal di Laragon/XAMPP lokal, lalu langsung push ke branch `development`:
```bash
git checkout -b development
git add .
git commit -m "feat: inisialisasi aplikasi php-native dengan template gitops"
git push -u origin development
```

### Jalur B: Uji Coba Container di Laptop (Jika Memiliki Docker)

> **Catatan Pengguna WSL 2 (Ubuntu)**: Jika Docker Anda terpasang di dalam distro Ubuntu WSL 2, jalankan perintah di bawah ini dari terminal Ubuntu WSL (`cd /mnt/c/laragon/www/nama-proyek`).

#### 1. Buat Jaringan `api-net` & Salin `.env`

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

#### 2. Build dan Jalankan di Docker Lokal
```bash
docker compose -f compose.yaml -f compose.build.yaml up -d --build
docker compose ps
```
Akses di browser: `http://localhost:8084` atau `http://localhost:8084/healthz.php`.
