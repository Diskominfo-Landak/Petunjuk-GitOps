# Panduan & Template GitOps Pemerintah Kabupaten Landak

Repositori ini merupakan pusat dokumentasi standar, panduan operasional, dan template kontainerisasi siap pakai untuk implementasi **GitOps** di lingkungan Pemerintah Kabupaten Landak (Diskominfo Landak).

---

## 🏗️ Arsitektur Singkat GitOps Pemkab Landak

Pola GitOps Pemkab Landak memodernisasi dan menyempurnakan referensi GitOps Pemprov Kalbar dengan penyesuaian infrastruktur nyata di Landak:

```
[ Developer ]
      │  (git push)
      ▼
[ GitHub Repository (diskominfo-landak) ]
      │
      ▼ (GitHub Actions CI: Test, Security Audit, Docker Multi-stage Build)
[ GitHub Container Registry (ghcr.io) ]
      │
      ├───> [ VM Development (10.20.10.10) ]
      │     Penarikan otomatis via cron (ops/update-dev.sh tiap 5 menit)
      │
      └───> [ VM Production ]
            Pemasangan terkontrol via skrip rilis bernomor (ops/release.sh)
            Dilengkapi Healthcheck & Auto-Rollback
```

### Keunggulan Dibanding Template Baseline Pemprov Kalbar:
1. **Keamanan Kredensial**: Tanpa menanam rahasia/password di Docker image (`--build-arg` dihapus). Semua kredensial runtime berada di file `.env` server dengan izin terbatas (`chmod 600`).
2. **Efisiensi CI/CD**: Memanfaatkan Runner GitHub Ubuntu resmi dan build caching cepat (`ghcr.io`), tanpa membebani server lokal untuk proses build.
3. **Stabilitas Rilis**: Sistem rilis SemVer (`vX.Y.Z`) yang melakukan verifikasi kontainer aktif dan rollback instan jika aplikasi gagal lolos uji kesehatan (*healthcheck*).

---

## 📁 Struktur Direktori Repositori

```text
gitops/
├── README.md                          # Ringkasan repositori (dokumen ini)
├── HANDOVER-SERAH-TERIMA.md           # Berkas teknis historis serah terima proyek
│
├── template/                          # Template siap pakai untuk proyek baru OPD
│   ├── laravel/                       # Template Laravel 12 + PHP 8.3 Alpine + MySQL 8.4
│   └── codeigniter/                   # Template CodeIgniter (CI 4 / CI 3) + PHP Alpine
│
├── ops/                               # Skrip operasional bersama untuk server/VM
│   ├── update-dev.sh                  # Skrip penarik image otomatis di VM Development
│   └── release.sh                     # Skrip rilis produksi dengan auto-rollback
│
└── docs/                              # Panduan lengkap sesuai peran
    ├── 01-standar-gitops-sop.md       # Standar penamaan, branch, SemVer, & bahan KepBup
    ├── 02-panduan-developer.md        # Panduan teknis untuk programmer/developer OPD
    ├── 03-panduan-admin-github.md     # Panduan kelola organisasi GitHub & GHCR
    ├── 04-panduan-infrastruktur-ops.md# Panduan Network Admin (setup VM, proxy, backup)
    └── 05-integrasi-sso-keycloak.md   # Panduan integrasi SSO Keycloak (ASN & Publik)
```

---

## 🚀 Memulai (Quick Start)

### 1. Bagi Pengembang Aplikasi (Developer)
Untuk memasang GitOps pada aplikasi baru atau aplikasi lama:
- Buka panduan di [`docs/02-panduan-developer.md`](file:///c:/Proyek/gitops/docs/02-panduan-developer.md).
- Salin berkas dari folder [`template/laravel`](file:///c:/Proyek/gitops/template/laravel) atau [`template/codeigniter`](file:///c:/Proyek/gitops/template/codeigniter) ke repositori Anda.

### 2. Bagi Administrator GitHub (Tim Aplikasi)
- Baca panduan tata kelola repositori di [`docs/03-panduan-admin-github.md`](file:///c:/Proyek/gitops/docs/03-panduan-admin-github.md).
- Pastikan izin workflow package diatur ke *Read and write permissions*.

### 3. Bagi Network Administrator / Tim Infrastruktur
- Baca panduan konfigurasi VM dan skrip rilis di [`docs/04-panduan-infrastruktur-ops.md`](file:///c:/Proyek/gitops/docs/04-panduan-infrastruktur-ops.md).
- Pasang skrip `ops/update-dev.sh` di crontab VM Development dan `ops/release.sh` di VM Production.
