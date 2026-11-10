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

## 🚀 Cara Menjalankan di Lokal Laptop

1. Masuk ke direktori `src/` dan install dependensi:
   ```bash
   cd src
   npm install
   cd ..
   ```
2. Buat jaringan Docker bersama:
   ```bash
   docker network create api-net 2>/dev/null || true
   ```
3. Siapkan file `.env`:
   ```bash
   cp .env.docker.example .env
   ```
4. Build dan jalankan di Docker lokal:
   ```bash
   docker compose -f compose.yaml -f compose.build.yaml up -d --build
   ```
5. Akses di browser: `http://localhost:8083` atau periksa endpoint healthcheck `http://localhost:8083/healthz`.

---

## ⚙️ 4 Titik Edit di `compose.yaml`

Sebelum push ke GitHub, sesuaikan penanda berikut:
1. `[EDIT 1/4]` : Nama proyek (`name: nama-aplikasi-node`).
2. `[EDIT 2/4]` : Image GHCR (`image: ghcr.io/diskominfo-landak/nama-aplikasi-node:${IMAGE_TAG:-development}`).
3. `[EDIT 3/4]` : Port lokal (misal `"127.0.0.1:8083:3000"`).
4. `[EDIT 4/4]` : Alias internal network (`- nama-aplikasi-node-web`).
