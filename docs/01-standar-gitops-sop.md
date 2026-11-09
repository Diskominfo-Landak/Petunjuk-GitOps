# Standar Operasional Prosedur (SOP) GitOps Pemkab Landak

Dokumen ini memuat standar penamaan, pengelolaan branch, alur rilis SemVer, serta kebijakan pengelolaan kredensial/rahasia di lingkungan Diskominfo Kabupaten Landak. Dokumen ini dapat diadaptasi sebagai lampiran teknis Keputusan Bupati (KepBup) atau SOP Layanan SPBE.

---

## 1. Kebijakan Repositori & Penamaan

- **Organisasi GitHub**: Seluruh repositori resmi berada di bawah organisasi GitHub Diskominfo Landak (`github.com/diskominfo-landak`).
- **Penamaan Repositori**: Huruf kecil, pemisah tanda hubung (`-`), mencerminkan fungsi atau nama sistem.
  - Contoh: `api-referensi`, `api-gateway`, `finda-app`.
- **Nama Image Container (GHCR)**:
  - Format: `ghcr.io/diskominfo-landak/<nama-repo>:<tag>`

---

## 2. Kebijakan Percabangan (Branching Strategy)

Sistem menggunakan alur kerja berbasis dua cabang utama:

1. **`development` (Lingkungan Uji / Development)**:
   - Cabang integrasi aktif.
   - Setiap `git push` ke cabang ini akan otomatis memicu build container di GitHub Actions dan mengunggah image dengan tag `development` serta tag hash singkat (`sha-xxxxxxx`).
   - VM Development menarik image ini secara otomatis melalui cron tiap 5 menit.
2. **`main` (Lingkungan Produksi / Stable)**:
   - Cabang kode sumber yang stabil dan siap rilis.
   - Penggabungan ke `main` dilakukan melalui **Pull Request (PR)** setelah pengujian di development tuntas.
3. **Tag Rilis Produksi (`vX.Y.Z`)**:
   - Rilis produksi **WAJIB** menggunakan tag Semantic Versioning (SemVer), contoh: `v1.0.0`, `v1.0.1`, `v1.1.0`.
   - Pembuatan tag ini di GitHub akan memicu workflow CI untuk mem-build image dengan tag bernomor (`1.0.0`) yang akan dipasang ke VM Production.

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

| Aktivitas | Tim Aplikasi (Developer) | Admin GitHub Organisasi | Network Administrator (Infrastruktur) |
|---|---|---|---|
| Penulisan Kode & Unit Test | **R**esponsible | **A**ccountable | **I**nformed |
| Pembuatan Repositori & Template | **C**onsulted | **R**esponsible / **A**ccountable | **I**nformed |
| Review PR ke Branch `main` | **R**esponsible | **A**ccountable | **I**nformed |
| Pembuatan Tag Rilis (`vX.Y.Z`) | **R**esponsible | **A**ccountable | **I**nformed |
| Penyediaan VM & Reverse Proxy | **I**nformed | **C**onsulted | **R**esponsible / **A**ccountable |
| Eksekusi Rilis ke VM Production | **I**nformed | **C**onsulted | **R**esponsible / **A**ccountable |
| Pemantauan Log & Kesehatan Server | **C**onsulted | **I**nformed | **R**esponsible / **A**ccountable |
