# Panduan Praktis untuk Developer (Pengembang Aplikasi)

Panduan ini ditujukan bagi programmer/developer di lingkungan Diskominfo Pemkab Landak untuk membuat, menguji di komputer lokal, dan mempublikasikan aplikasi ke lingkungan GitOps.

---

## 1. Menyiapkan Proyek Baru Menggunakan Template

Pilih template yang sesuai dengan teknologi yang Anda gunakan:
- **Laravel 12 (PHP 8.3)**: `template/laravel/`
- **CodeIgniter (PHP 8.2 / 7.4)**: `template/codeigniter/`

Salin berkas konfigurasi dari folder template ke root proyek Anda:
```bash
# Contoh untuk proyek Laravel:
cp -r template/laravel/* /path/ke/proyek-anda/
cp template/laravel/.github/workflows/ci.yml /path/ke/proyek-anda/.github/workflows/
```

### Konfigurasi Awal di Proyek Anda:
1. Buka `compose.yaml`:
   - Ganti `name: nama-aplikasi` dengan nama repositori Anda.
   - Ganti baris `image:` menjadi `ghcr.io/diskominfo-landak/<nama-repo>:${IMAGE_TAG:-development}`.
   - **Tentukan Tipe Aplikasi:**
     - Jika aplikasi memiliki tampilan web (UI pengguna), buka port port-mapping lokal (misal: `"127.0.0.1:808X:80"`).
     - Jika aplikasi adalah microservice/API internal, matikan mapping port ke host agar hanya bisa diakses via internal network `api-net`.
2. Buat file `.env` lokal dari `.env.docker.example` untuk pengujian lokal.

---

## 2. Menjalankan & Menguji Aplikasi di Komputer Lokal

Untuk menguji container aplikasi di komputer lokal (Laptop / PC pengembang), gunakan opsi `compose.build.yaml` agar Docker melakukan build lokal dari kode sumber:

```bash
# Build dan jalankan container di lokal:
docker compose -f compose.yaml -f compose.build.yaml up -d --build

# Melihat log aplikasi:
docker compose logs -f app

# Mengakses container PHP untuk artisan atau debugging:
docker compose exec app sh

# Menghentikan container:
docker compose down
```

---

## 3. Alur Kerja Git & Publikasi Fitur

### A. Alur Pengembangan Harian (Branch `development`)
1. Kembangkan fitur di branch fitur lokal Anda (`feature/nama-fitur`).
2. Gabungkan (*merge*) ke branch `development` lokal, lalu push ke GitHub:
   ```bash
   git checkout development
   git merge feature/nama-fitur
   git push origin development
   ```
3. GitHub Actions otomatis melakukan:
   - Linting & Unit Test
   - Audit celah keamanan dependensi (`composer audit`)
   - Build image container dan push ke `ghcr.io/diskominfo-landak/<nama-repo>:development`
4. Maksimal dalam 5 menit, VM Development akan menarik image terbaru tersebut dan memperbarui aplikasi di server uji.

### B. Alur Rilis ke Produksi (Branch `main` & Tag Versi)
1. Setelah fitur teruji di VM Development, buat **Pull Request (PR)** dari `development` ke `main`.
2. Minta review kepada Lead Developer / Admin GitHub Organisasi.
3. Setelah PR di-merge ke `main`, buat tag rilis versi baru sesuai SemVer:
   ```bash
   git checkout main
   git pull origin main
   git tag v1.0.1 -m "Rilis v1.0.1: Perbaikan bug login dan update modul wilayah"
   git push origin v1.0.1
   ```
4. GitHub Actions akan mem-build image dengan tag bernomor (`1.0.1`).
5. Informasikan kepada **Network Administrator** untuk memasang rilis tersebut ke VM Production.
