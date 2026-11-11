# Standar Operasional Prosedur (SOP) GitOps Pemkab Landak

Dokumen ini memuat standar penamaan, pengelolaan branch, alur rilis SemVer, serta kebijakan pengelolaan kredensial/rahasia di lingkungan Diskominfo Kabupaten Landak. Dokumen ini dapat diadaptasi sebagai lampiran teknis Keputusan Bupati (KepBup) atau SOP Layanan SPBE.

---

## 1. Kebijakan Repositori & Penamaan Subdomain

Sesuai dengan *Juknis Pedoman Pembangunan dan Pengembangan Aplikasi Pemkab Landak*:

1. **Organisasi GitHub Terpusat**: Seluruh repositori resmi wajib berada di bawah organisasi GitHub resmi Diskominfo Landak (`github.com/diskominfo-landak`).
2. **Standar Penamaan Repositori**: 
   - Wajib menggunakan huruf kecil dan tanda hubung (`-`).
   - **Nama repositori diselaraskan langsung dengan nama subdomain produksi aplikasi**.
   - *Contoh*: Jika aplikasi beralamat di `https://simpeg.landakkab.go.id`, maka nama repositorinya wajib **`simpeg`** (atau `simpeg-app`).
3. **Pemberian Domain Lingkungan Uji (Development)**:
   - GitOps Administrator / Network Administrator secara otomatis akan menetapkan domain development dengan format:
     `https://<nama-subdomain>-dev.landakkab.go.id` (contoh: `https://simpeg-dev.landakkab.go.id`).
4. **Nama Image Container (GHCR)**:
   - Format: `ghcr.io/diskominfo-landak/<nama-repo>:<tag>`

---

## 2. Kebijakan Percabangan (Branching Strategy)

Sistem menggunakan alur kerja berbasis dua cabang utama:

1. **`development` (Lingkungan Uji / Development)**:
   - Cabang integrasi aktif harian bagi pengembang.
   - Setiap `git push` ke cabang ini otomatis memicu build container di GitHub Actions dan mengunggah image dengan tag `development` serta tag hash singkat (`sha-xxxxxxx`).
   - VM Development menarik image ini secara otomatis melalui cron tiap 5 menit.
2. **`main` (Lingkungan Produksi / Stable)**:
   - Cabang kode sumber yang stabil dan siap rilis.
   - Penggabungan kode ke `main` **hanya boleh dilakukan melalui Pull Request (PR)** setelah pengujian di VM development dinyatakan tuntas.
3. **Tag Rilis Produksi (`vX.Y.Z`)**:
   - Rilis produksi **WAJIB** menggunakan tag Semantic Versioning (SemVer), contoh: `v1.0.0`, `v1.0.1`, `v1.1.0`.
   - Pembuatan tag ini di GitHub akan memicu workflow CI untuk mem-build image dengan tag bernomor (`1.0.0`) yang akan dipasang ke VM Production oleh Network Administrator.

---

## 3. Kebijakan Keamanan Kredensial & Secrets

1. **Larangan Menanam Rahasia di Image**:
   - Dilarang keras menggunakan `--build-arg` untuk menanam password database, API key, atau token ke dalam image Docker.
2. **Penyimpanan Kredensial di Server**:
   - Seluruh rahasia runtime wajib disimpan dalam file `.env` di server target (`/opt/apps/<proyek>/.env`).
   - Hak akses file `.env` diatur secara ketat (`chmod 600 .env`) dan dimiliki oleh pengguna non-root/administrator.
3. **Penyimpanan Token CI/CD**:
   - Runner GitHub Actions hanya menggunakan token bawaan `${{ secrets.GITHUB_TOKEN }}` untuk otentikasi ke GitHub Container Registry (`ghcr.io`). Tidak diperlukan token eksternal.

---

## 4. Matriks Tanggung Jawab (RACI)

Tatanan tata kelola GitOps Pemkab Landak dibagi ke dalam **3 Peran Utama**:
1. **Developer (Pengembang Aplikasi)**
2. **GitOps Administrator (Pengelola Repositori GitHub & VM Development)**
3. **Network Administrator (Pengelola Infrastruktur Jaringan, Server Fisik, & VM Production)**

### Definisi Tingkat Peran (RACI):
- **Responsible (R)**: Pihak yang bertugas mengeksekusi dan menyelesaikan pekerjaan teknis secara langsung.
- **Accountable (A)**: Pihak yang memegang tanggung jawab akhir, berhak mengambil keputusan/persetujuan (*approval*), dan memastikan pekerjaan tuntas. Hanya ada 1 pihak Accountable per aktivitas.
- **Consulted (C)**: Pihak yang dimintai masukan, pendapat, atau koordinasi dua arah sebelum keputusan/tindakan diambil.
- **Informed (I)**: Pihak yang mendapatkan pemberitahuan atau laporan satu arah mengenai progres atau hasil pekerjaan.

### Matriks Aktivitas:

| Aktivitas | Developer | GitOps Administrator | Network Administrator |
|---|---|---|---|
| Penulisan Kode, Migrasi DB, & Unit Test | **R**esponsible | **A**ccountable | **I**nformed |
| Pembuatan Repositori & Template | **C**onsulted | **R**esponsible / **A**ccountable | **I**nformed |
| Inisialisasi Aplikasi di VM Dev (`.env`, port, cron) | **I**nformed | **R**esponsible / **A**ccountable | **C**onsulted |
| Review PR ke Branch `main` | **R**esponsible | **A**ccountable | **I**nformed |
| Pembuatan Tag Rilis SemVer (`vX.Y.Z`) | **R**esponsible | **A**ccountable | **I**nformed |
| Penyediaan VM & Reverse Proxy SSL | **I**nformed | **C**onsulted | **R**esponsible / **A**ccountable |
| Eksekusi Rilis ke VM Production | **I**nformed | **C**onsulted | **R**esponsible / **A**ccountable |
| Pemantauan Log, Resource, & Backup Server | **C**onsulted | **I**nformed | **R**esponsible / **A**ccountable |

### Rujukan Panduan Praktis Developer:
- Bagi **Developer**: Ikuti tutorial lengkap pembuatan aplikasi, pengujian lokal, dan Git remote di [`docs/02-panduan-developer.md`](02-panduan-developer.md).
