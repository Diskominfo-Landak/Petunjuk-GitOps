# Template GitOps Node.js (Pemkab Landak)

Template kontainerisasi siap pakai untuk aplikasi berbasis **Node.js** (Express, Fastify, NestJS, atau SSR) yang diselaraskan dengan standar GitOps Pemerintah Kabupaten Landak.

---

## 📁 Struktur Direktori

```text
.
├── Dockerfile                  # Build multi-stage Node 20 Alpine (non-root)
├── .dockerignore               # Abaikan node_modules, log, dan file rahasia
├── .gitignore
├── .gitattributes              # Menjaga line-ending LF
├── compose.yaml                # Konfigurasi container runtime di VM
├── compose.build.yaml          # Override build lokal untuk laptop developer
├── .env.docker.example         # Template variabel environment
├── .github/workflows/ci.yml    # Pipeline CI/CD GitHub Actions ke GHCR
└── src/                        # << KODE APLIKASI NODE.JS ANDA >>
    ├── package.json
    ├── server.js               # Contoh server Express dengan healthcheck /healthz
    └── test/                   # Unit test
```

---

## ⚙️ 4 Titik Edit di `compose.yaml` & `.env.docker.example`

Sebelum push ke GitHub, sesuaikan penanda berikut di `compose.yaml`:
1. `[EDIT 1/4]` : Nama proyek (`name: nama-aplikasi-node`).
2. `[EDIT 2/4]` : Image GHCR (`image: ghcr.io/diskominfo-landak/nama-aplikasi-node:${IMAGE_TAG:-development}`).
3. `[EDIT 3/4]` : Port lokal (misal `"127.0.0.1:8083:3000"`). Nomor port ini ditentukan 1 kali bersama Admin Infrastruktur dan **tidak perlu diubah** saat merge ke `main`.
4. `[EDIT 4/4]` : Alias internal network (`- nama-aplikasi-node-web`).

Di file `.env.docker.example`:
- Biarkan `NODE_ENV=production` dan isi `APP_URL` dengan subdomain produksi resmi.
- Jika memakai database container (`db`), pastikan `DB_HOST=db` (bukan `127.0.0.1`) dan `DB_USERNAME` menggunakan nama user biasa (**dilarang mengisi `root`**).

---

## 🚀 Pengujian & Publikasi (Pilih Sesuai Spesifikasi Laptop)

### Jalur A: Laptop Tanpa Docker (Langsung Push ke GitHub)

Jika komputer Anda belum terpasang Docker:

1. **Langkah 1 — Minta Nama Repositori & Hak Akses ke Admin GitOps**:
   - Sampaikan username GitHub Anda ke **Admin GitOps** untuk dibuatkan repositori resmi di `https://github.com/Diskominfo-Landak/<nama-repo>` dan diundang sebagai kolaborator.
   - Minta juga alokasi **nomor port upstream** internal (misal: `8083`) untuk penanda `[EDIT 3/4]` di `compose.yaml`.

2. **Langkah 2 — Pastikan Aplikasi Lokal Siap**:
   - Uji aplikasi Node.js secara lokal (`cd src && npm install && npm test && cd ..`).
   - Pastikan penanda `[EDIT 1/4]` s.d. `[EDIT 4/4]` di `compose.yaml` dan `.env.docker.example` sudah disesuaikan dengan `<nama-repo>`.

3. **Langkah 3 — Inisialisasi Git Remote & Push Pertama Kali**:
   ```bash
   cd /path/ke/proyek-nodejs
   git init
   git checkout -b development

   # Periksa remote dan set URL repositori resmi dari Admin GitOps:
   git remote -v
   git remote add origin https://github.com/Diskominfo-Landak/<nama-repo>.git
   # (atau 'git remote set-url origin ...' jika remote sudah pernah ada)

   git add .
   git commit -m "feat: inisialisasi aplikasi nodejs dengan template gitops"
   git push -u origin development
   ```
   > 💡 Flag `-u origin development` hanya dijalankan **1 kali di awal**. Untuk push selanjutnya, cukup ketik `git push`.

4. **Langkah 4 — Pantau CI/CD GitHub Actions**:
   Buka tab **Actions** di GitHub untuk melihat proses build image dan deployment otomatis ke VM Development!

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
Akses di browser: `http://localhost:8083` atau periksa endpoint healthcheck `http://localhost:8083/healthz`.
