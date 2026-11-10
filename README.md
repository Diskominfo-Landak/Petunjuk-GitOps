# Panduan & Template GitOps Pemerintah Kabupaten Landak

Repositori ini merupakan pusat dokumentasi standar, panduan pengembang aplikasi, dan template kontainerisasi siap pakai untuk implementasi **GitOps** di lingkungan Pemerintah Kabupaten Landak (Diskominfo Landak).

---

## 🏗️ Arsitektur Singkat GitOps Pemkab Landak

Pola GitOps Pemkab Landak memodernisasi alur pengembangan aplikasi di lingkungan Pemkab Landak:

```
[ Developer ]
      │  (git push)
      ▼
[ GitHub Repository (diskominfo-landak) ]
      │
      ▼ (GitHub Actions CI: Test, Security Audit, Docker Multi-stage Build)
[ GitHub Container Registry (ghcr.io) ]
      │
      ├───> [ VM Development (Server Uji) ]
      │     Penarikan otomatis via cron (ops/update-dev.sh tiap 5 menit)
      │
      └───> [ VM Production ]
            Pemasangan terkontrol via skrip rilis bernomor (ops/release.sh)
            Dilengkapi Healthcheck & Auto-Rollback
```

### Keunggulan Alur GitOps:
1. **Keamanan Kredensial**: Tanpa menanam rahasia/password di Docker image (`--build-arg` dihindari). Semua kredensial runtime berada di file `.env` server dengan izin terbatas (`chmod 600`).
2. **Efisiensi CI/CD**: Memanfaatkan Runner GitHub Ubuntu resmi dan build caching cepat (`ghcr.io`), tanpa membebani server lokal untuk proses build.
3. **Stabilitas Rilis**: Sistem rilis SemVer (`vX.Y.Z`) yang melakukan verifikasi kontainer aktif dan rollback instan jika aplikasi gagal lolos uji kesehatan (*healthcheck*).

---

## 📁 Struktur Direktori Repositori

```text
Petunjuk-GitOps/
├── README.md                          # Ringkasan repositori (dokumen ini)
│
├── template/                          # Template siap pakai untuk proyek baru OPD
│   ├── laravel/                       # Template Laravel 12 + PHP 8.3 Alpine + MySQL 8.4
│   ├── codeigniter/                   # Template CodeIgniter (CI 4 / CI 3) + PHP Alpine
│   ├── nodejs/                        # Template Node.js 20 Alpine (Express / API / SSR)
│   └── php-native/                    # Template PHP Native / Legacy + Nginx
│
├── ops/                               # Skrip operasional rujukan untuk server
│   ├── update-dev.sh                  # Skrip penarik image otomatis di VM Development
│   └── release.sh                     # Skrip rilis produksi dengan auto-rollback
│
└── docs/                              # Panduan pengembangan aplikasi & arsitektur
    ├── 01-standar-gitops-sop.md       # Standar penamaan, branch, SemVer, & alur rilis
    ├── 02-panduan-developer.md        # Panduan teknis untuk programmer/developer OPD
    ├── 03-integrasi-sso.md            # Konsep arsitektur SSO Pemkab Landak (ASN & Publik)
    ├── 04-arsitektur-keselarasan-kalbar-swarm.md # Arsitektur keselarasan (Swarm vs Compose)
    ├── panduan-sso-laravel.md         # Tutorial integrasi SSO untuk Laravel
    └── panduan-sso-codeigniter.md     # Tutorial integrasi SSO untuk CodeIgniter 4
```

---

## 🚀 Memulai (Quick Start untuk Developer)

Bagi pengembang sistem atau programmer OPD yang ingin menerapkan standar GitOps pada aplikasi baru atau yang sudah berjalan:

1. Pelajari tata cara branch dan standar Semantic Versioning di [`docs/01-standar-gitops-sop.md`](docs/01-standar-gitops-sop.md).
2. Ikuti langkah pembuatan dan pengujian lokal di [`docs/02-panduan-developer.md`](docs/02-panduan-developer.md).
3. Salin berkas konfigurasi dari folder template yang sesuai ke repositori aplikasi Anda:
   - [`template/laravel`](template/laravel) (Laravel 12 / PHP 8.3)
   - [`template/codeigniter`](template/codeigniter) (CodeIgniter 4 / CI 3)
   - [`template/nodejs`](template/nodejs) (Node.js 20 / Express)
   - [`template/php-native`](template/php-native) (PHP Native / Legacy)
4. Jika aplikasi membutuhkan autentikasi login pengguna:
   - Pelajari konsep SSO di [`docs/03-integrasi-sso.md`](docs/03-integrasi-sso.md).
   - Ikuti tutorial teknis sesuai framework Anda: [`docs/panduan-sso-laravel.md`](docs/panduan-sso-laravel.md) atau [`docs/panduan-sso-codeigniter.md`](docs/panduan-sso-codeigniter.md).
5. Pelajari perbandingan arsitektur teknis dan justifikasi regulasi KepBup di [`docs/04-arsitektur-keselarasan-kalbar-swarm.md`](docs/04-arsitektur-keselarasan-kalbar-swarm.md).
