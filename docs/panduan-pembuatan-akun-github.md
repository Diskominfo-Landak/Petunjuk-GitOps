# Panduan Pembuatan Akun GitHub & Onboarding Pengembang Baru

Panduan ini ditujukan bagi programmer baru, tenaga magang, atau pengembang di lingkungan Pemkab Landak yang belum pernah menggunakan GitHub, untuk menyiapkan akun resmi, mengamankannya dengan 2FA, dan terhubung ke organisasi **`diskominfo-landak`**.

---

## 1. Mendaftar Akun GitHub Baru (Gratis)

1. Buka situs resmi GitHub: [https://github.com/signup](https://github.com/signup).
2. Masukkan alamat email aktif Anda.
3. Buat password yang kuat (kombinasi huruf besar, kecil, angka, dan simbol).
4. Tentukan **Username** GitHub Anda:
   - Gunakan nama yang profesional dan mudah dikenali (contoh: `budi-landak`, `alfin-aptika`, atau nama asli Anda).
5. Selesaikan verifikasi captcha dan masukkan kode verifikasi yang dikirimkan ke email Anda.

---

## 2. Pengaturan Profil & Standarisasi Identitas

Agar GitOps Administrator dapat mengenali akun Anda di dalam repositori resmi dinas:

1. Klik foto profil Anda di pojok kanan atas $\to$ **Settings** $\to$ **Public profile**.
2. **Name**: Tuliskan nama lengkap Anda (contoh: `Budi Setiawan`).
3. **Company**: Isi dengan `Diskominfo Kabupaten Landak` (atau nama OPD / Kampus bagi pemagang).
4. **Location**: `Kabupaten Landak, Kalimantan Barat`.
5. Klik **Update profile**.

---

## 3. Wajib: Mengaktifkan Two-Factor Authentication (2FA)

Untuk mematuhi standar keamanan siber Pemkab Landak dan kebijakan resmi GitHub, seluruh anggota organisasi **wajib mengaktifkan autentikasi 2 faktor (2FA)**:

1. Di menu **Settings**, klik tab **Password and authentication** (di sidebar kiri).
2. Scroll ke bagian **Two-factor authentication** $\to$ klik **Enable two-factor authentication**.
3. Buka aplikasi authenticator di smartphone Anda (contoh: **Google Authenticator** atau **Microsoft Authenticator**).
4. Pindai (scan) kode QR yang tampil di layar komputer dengan aplikasi authenticator di HP Anda.
5. Masukkan 6 digit kode angka yang muncul di HP untuk konfirmasi.
6. **SIMPAN KODE PEMULIHAN (Recovery Codes)**:
   - Unduh atau simpan recovery codes di tempat yang aman. Kode ini berguna jika HP Anda hilang/rusak agar Anda tetap bisa login.

---

## 4. Konfigurasi Git di Laptop / Komputer Lokal

Buka terminal (Git Bash, Command Prompt, atau Terminal VS Code) di laptop Anda, lalu jalankan perintah berikut agar commit Git Anda tercatat atas nama Anda:

```bash
# 1. Daftarkan nama lengkap Anda:
git config --global user.name "Nama Lengkap Anda"

# 2. Daftarkan email yang sama dengan email akun GitHub Anda:
git config --global user.email "email-anda@domain.com"

# 3. Pastikan konfigurasi tersimpan dengan benar:
git config --global --list
```

---

## 5. Cara Mengajukan Akses ke Organisasi `diskominfo-landak`

Setelah akun GitHub Anda siap dan 2FA telah aktif:

1. Hubungi **GitOps Administrator** Diskominfo Landak (Koordinator Aplikasi Aptika) melalui chat kedinasan.
2. Sampaikan permohonan akses dengan format:
   > *"Halo Admin GitOps, saya [Nama Lengkap] (Programmer / Tenaga Magang di [Nama Bidang/OPD]) telah membuat akun GitHub dengan username: **`@username-anda`**. Mohon dapat dimasukkan sebagai kontributor di organisasi Diskominfo Landak untuk proyek aplikasi [Nama Aplikasi]."*
3. GitOps Administrator akan mengirimkan undangan ke akun Anda.
4. Buka email Anda atau kunjungi tautan: [https://github.com/diskominfo-landak](https://github.com/diskominfo-landak), lalu klik tombol **Accept invitation**.
5. Selamat! Anda sekarang telah resmi tergabung dan dapat melakukan `git clone` serta berkontribusi pada repositori dinas.
