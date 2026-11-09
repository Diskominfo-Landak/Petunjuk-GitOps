# Checkpoint Proyek API Gateway & API Referensi (Pemkab Landak)

**Tanggal:** 9 November 2026  
**Status Sesi:** Langkah 1, Langkah 2, dan Langkah 3 **SELESAI PENUH (100% SUKSES)**. Siap lanjut ke **Langkah 4**.

---

## 1. Yang Sudah Selesai Dikerjakan

### Langkah 1: Pembersihan & Perbaikan di Laptop (Laragon & Git)
1. **Pembersihan File Nyasar / Tertimpa:**
   - `C:\laragon\www\api-referensi\.env.example` dikembalikan ke template bawaan Laravel.
   - File salah kamar `C:\laragon\www\api-gateway\.env.docker.example` telah dihapus.
2. **Pengujian Unit Lokal:**
   - PHPUnit di `api-referensi` dijalankan dan lulus penuh: `OK (10 tests, 36 assertions)`.
3. **Penyempurnaan Skrip Deploy:**
   - `deploy/update-dev.sh`: Ditambahkan `unset IMAGE_TAG` agar tidak bentrok dengan env sesi shell.
   - `deploy/release.sh`:
     - Ditambahkan `unset IMAGE_TAG`.
     - Ditambahkan fungsi verifikasi container berjalan (`verify_running`).
     - Hapus flag `-q` pada `git fetch --tags` agar error Git tampil jelas.
     - Rollback otomatis dikembalikan ke branch aktif (`development`), bukan detached commit hash.
     - Seluruh alur dibungkus dalam fungsi `main`.
   - Perubahan di-commit dan di-push ke branch `origin/development`.
4. **Perapian Tag & Dokumentasi:**
   - Dibuat dan di-push tag resmi `v0.0.2` pada kedua repo (`api-referensi` dan `api-gateway`).
   - Dokumen panduan diperbarui tanpa trik `set -a`.

---

### Langkah 2: Gladi Resik / Uji Release & Rollback di VM Dev
Semua pengujian di VM development (`10.20.10.10`) berhasil 100%:
1. **Latihan 1 (Pasang Versi Bernomor `0.0.2`):** Sukses, healthcheck 200 OK.
2. **Latihan 2 (Rollback Otomatis saat Image Tidak Ada):** Sukses mendeteksi failure dan auto-rollback ke 0.0.2 dengan aman.
3. **Latihan 3 (Proteksi Tag Tidak Ada di Git):** Berhenti di awal tanpa merusak state.
4. **Pemulihan VM Dev:** Dikembalikan ke branch `* development` dan image `development`.

---

### Langkah 3: Eksekusi Seeder OPD, Hardening Keamanan & Maintenance VM
Semua instruksi Langkah 3 berhasil dieksekusi di VM dev:
1. **Jalankan `UnitKerjaSeeder`:** Berhasil dieksekusi, database terisi total **59 Unit Kerja/OPD**.
2. **Kunci Hak Akses `.env`:** Izin akses ketiga file `.env` telah dikunci ke `600` (`-rw-------`).
3. **Proteksi Disk Docker (`/etc/docker/daemon.json`):** Berhasil dikonfigurasi (`max-size: 10m`, `max-file: 5`), daemon di-restart, dan container aktif menggunakan konfigurasi log baru.
4. **Backup Database Otomatis & Crontab:** 
   - Tes backup manual `api_referensi-2026-11-09.sql.gz` berhasil (ukuran 786 KB).
   - Crontab harian backup (jam 02:00), pembersihan retensi 14 hari (jam 02:30), dan auto-update cron (tiap 5 menit) sudah terpasang dan aktif.

---

## 2. Kondisi Saat Ini

- **Laptop:**
  - `C:\laragon\www\api-referensi` (branch `development`, clean).
  - `C:\laragon\www\api-gateway` (branch `development`, clean).
- **VM Dev (`10.20.10.10`):**
  - Branch `development`, image `development`.
  - Seluruh service sehat: `db`, `app`, `web`, `gateway`, `loki`, `alloy`, `grafana`.
  - Database terisi lengkap (Wilayah, Tipe Unit Kerja, dan 59 Master OPD Pemkab Landak).
  - Log limiter dan auto-backup aktif.

---

## 3. Rencana Kerja Selanjutnya: Langkah 4

1. **Pembuatan Branch `main` di Kedua Repositori (Laptop):**
   - Buat dan push branch `main` dari `development` untuk `api-referensi` dan `api-gateway`.
2. **Review & Finalisasi Panduan Network Administrator (Production):**
   - Menyiapkan dokumen kesiapan dan SOP serah terima rilis produksi untuk Network Administrator.
