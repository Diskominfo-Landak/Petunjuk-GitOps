# Panduan Export Database Lokal bagi Pengembang (Developer Guide: Export to VM GitOps)

Dokumen ini merupakan panduan praktis bagi **Programmer / Developer OPD** di lingkungan Pemerintah Kabupaten Landak untuk mengekspor database dari komputer lokal (Laragon / XAMPP / Docker Lokal) agar siap diimpor ke server **VM Development** atau **VM Production** oleh GitOps Administrator.

---

## 1. Mengapa Perlu Panduan Khusus Export Database?

Pada alur GitOps modern Pemkab Landak:
1. Server VM secara otomatis membuat struktur tabel saat container pertama kali dijalankan via perintah migrasi framework (`php artisan migrate --force`).
2. Server VM juga secara otomatis menjalankan seeder master bawaan (`php artisan db:seed --force`), seperti master 59 OPD Landak, modul sistem, peran pengguna (*roles*), dan akun superadmin default.

Jika pengembang mengekspor seluruh database secara mentah (*full dump*) lalu menimpakannya ke server, sistem server akan mengalami bentrok serius:
* **Error 1050 (Table already exists)**: Struktur tabel bentrok dengan migrasi.
* **Error 1062 (Duplicate entry for key 'PRIMARY')**: Data akun superadmin atau ID master hasil seeder bertabrakan dengan ID dari laptop pengembang.
* **Error 1451 (Cannot delete or update a parent row)**: Foreign Key constraint gagal karena urutan dump data tidak sesuai relasi.

Oleh karena itu, pengembang wajib mengikuti kaidah ekspor yang rapi dan terstandarisasi di bawah ini.

---

## 2. Tiga Aturan Mutlak bagi Pengembang

> [!CAUTION]
> ### 1. DILARANG KERAS Commit File `.sql` ke Repositori Git!
> - File database dump sering kali berukuran besar dan akan memperlambat proses `git clone` / `git pull`.
> - File dump rentan memuat data kredensial, hash password, atau informasi sensitif.
> - Seluruh file `.sql` sudah dimasukkan ke dalam `.gitignore` repositori. Penyerahan file database dilakukan melalui **jalur privat terpisah** (Google Drive kedinasan Diskominfo / flashdisk / chat internal ke Admin GitOps).

> [!IMPORTANT]
> ### 2. Wajib Patuhi UU No. 27 Tahun 2022 tentang Perlindungan Data Pribadi (UU PDP)
> Untuk lingkungan **VM Development**, dilarang mengekspor data pribadi riil ASN atau masyarakat (seperti NIK asli, nomor KK, nomor handphone riil, atau data rekam medis). Pastikan data yang diekspor adalah **data dummy / data uji coba / data yang telah disanitasi**.

> [!NOTE]
> ### 3. Independensi Nama Database
> Anda tidak perlu khawatir jika nama database di laptop Anda berbeda dengan di server (contoh: di laptop Anda bernama `db_aplikasi_lokal`, sedangkan di server bernama `db_aplikasi_dev`). File dump SQL baris data bersifat *portable* dan Admin GitOps akan mengarahkannya ke database aktif di server.

---

## 3. Memahami Kategori Data: Mana yang Perlu Diekspor?

Sebelum mengekspor, pilah tabel-tabel di database lokal Anda ke dalam dua kategori:

| Kategori Tabel | Contoh Tabel | Perlakuan Ekspor |
|---|---|---|
| **Data Master & Konfigurasi Sistem (Seeder)** | `users` (admin awal), `roles`, `permissions`, `modules`, `unit_kerjas` (59 OPD) | **JANGAN DIEKSPOR** jika server sudah memiliki seedernya. Cukup biarkan seeder server yang mengisinya. |
| **Data Transaksi & Inputan Riil (Operasional)** | `layanan_aduan`, `riwayat_aduan`, `surat_masuk`, `dokumen_perizinan`, `artikel_berita` | **WAJIB DIEKSPOR** menggunakan metode *Data-Only* (`--no-create-info`). |

---

## 4. Dua Skenario Ekspor Database

### SKENARIO A: Ekspor Data Transaksi Saja Tanpa Struktur (`--no-create-info --insert-ignore`)
> **Metode Paling Direkomendasikan (90% Kasus)**  
> Gunakan metode ini jika container server sudah menjalankan migrasi tabel dan seeder, lalu Anda ingin mengirimkan data inputan/transaksi yang sudah Anda input di lokal.

**Keuntungan:**
* Tidak mengubah atau merusak skema tabel di server.
* Opsi `--insert-ignore` menjamin jika ada ID yang kebetulan sama dengan data seeder server, baris tersebut akan **dilewati secara aman** tanpa menggagalkan proses impor.

---

### SKENARIO B: Ekspor Lengkap Struktur + Data (Full Dump)
> Gunakan metode ini **HANYA JIKA** aplikasi Anda adalah aplikasi baru yang belum memiliki file migrasi framework (misal PHP Native/Legacy), sehingga server membutuhkan struktur tabel dari nol.

---

## 5. Cara Ekspor via Command Line (`mysqldump`)

Bagi pengguna Windows dengan **Laragon** atau **XAMPP**, buka PowerShell atau Command Prompt.

### A. Cari Lokasi `mysqldump.exe`
* **Laragon**: `C:\laragon\bin\mysql\mysql-8.0.xx-winx64\bin\mysqldump.exe`
* **XAMPP**: `C:\xampp\mysql\bin\mysqldump.exe`

*(Jika path MySQL sudah masuk ke Environment Variables / PATH, Anda cukup mengetik `mysqldump`).*

---

### B. Perintah Ekspor Skenario A: Data-Only Selektif (Rekomendasi)

Jika Anda ingin mengekspor **hanya tabel transaksi tertentu** (contoh: tabel `layanan_aduan` dan `riwayat_aduan`):

```bash
# Format: mysqldump -u <user> -p --no-create-info --insert-ignore --complete-insert <nama_db> <tabel_1> <tabel_2> > export_data.sql

mysqldump -u root -p --no-create-info --insert-ignore --complete-insert db_aplikasi_lokal layanan_aduan riwayat_aduan > aduan_transaksi_20261119.sql
```

Jika Anda ingin mengekspor **seluruh tabel data tanpa struktur**, abaikan tabel migrasi framework:

```bash
# Laravel / CodeIgniter: Abaikan tabel migrations
mysqldump -u root -p --no-create-info --insert-ignore --complete-insert --ignore-table=db_aplikasi_lokal.migrations db_aplikasi_lokal > aplikasi_semua_data_20261119.sql
```

**Penjelasan Flag:**
* `--no-create-info`: Hanya menghasilkan query `INSERT INTO`, tanpa perintah `CREATE TABLE` atau `DROP TABLE`.
* `--insert-ignore`: Menghasilkan `INSERT IGNORE INTO` sehingga jika ada data bentrok di server, query tidak berhenti dengan pesan error.
* `--complete-insert`: Menyertakan nama-nama kolom pada query insert (`INSERT INTO table (col1, col2) VALUES (...)`), menjamin query tetap valid meskipun urutan kolom di server sedikit berbeda.

---

### C. Perintah Ekspor Skenario B: Full Database (Aplikasi Legacy)

```bash
mysqldump -u root -p --routines --triggers --single-transaction nama_database_lokal > aplikasi_full_20261119.sql
```

---

## 6. Cara Ekspor via Graphical Tool (GUI)

Jika Anda lebih terbiasa menggunakan antarmuka grafis daripada terminal:

### Opsi 1: Menggunakan HeidiSQL (Bawaan Standar Laragon)

1. Buka **HeidiSQL** dan hubungkan ke sesi MySQL lokal Anda.
2. Klik kanan pada nama database lokal Anda di panel sebelah kiri $\to$ pilih **Export database as SQL**.
3. Di jendela pengaturan ekspor:
   * **Database(s)**: Centang database Anda.
   * **Table(s)**:
     - Jika Skenario A (Data-Only): Centang hanya tabel-tabel transaksi yang ingin diekspor.
   * **Dropdown 'Table: Create'**: Pilih **No create** (agar tidak membuat struktur tabel baru).
   * **Dropdown 'Data'**: Pilih **Insert (with standard INSERT statements)** atau **Insert ignore**.
   * **Output**: Pilih **Single .sql file** dan tentukan lokasi penyimpanan (misal: `D:\dump\data_transaksi.sql`).
4. Klik tombol **Export**.

---

### Opsi 2: Menggunakan DBeaver

1. Buka **DBeaver** $\to$ Klik kanan pada tabel yang ingin diekspor (atau pilih beberapa tabel transaksi sekaligus).
2. Pilih **Export Data** $\to$ Pilih target format **SQL**.
3. Pada halaman konfigurasi SQL:
   * Hilangkan centang **Include generated DDL (CREATE TABLE)**.
   * Centang **Use INSERT IGNORE** (jika tersedia).
4. Klik **Next** $\to$ Tentukan lokasi file `.sql` tujuan $\to$ Klik **Proceed**.

---

### Opsi 3: Menggunakan phpMyAdmin (Bawaan XAMPP)

1. Buka `http://localhost/phpmyadmin` di browser.
2. Klik database Anda $\to$ Pilih tab **Export (Ekspor)** di menu atas.
3. Pilih metode **Custom (Kustom - perlihatkan semua opsi yang mungkin)**.
4. Pada bagian **Tables (Tabel)**: Centang hanya tabel transaksi yang relevan.
5. Pada bagian **Format-specific options (Opsi keluaran data)**:
   * Format: **SQL**.
   * Format creation options: Centang hanya **data**, **JANGAN** centang structure (struktur).
   * Syntax to use when inserting data: Pilih **INSERT IGNORE**.
6. Klik tombol **Export (Ekspor)** untuk mengunduh file `.sql`.

---

## 7. Format Penamaan File & Checklist Handover ke GitOps Administrator

Sebelum menyerahkan file dump ke Admin GitOps, pastikan Anda telah memeriksa checklist berikut:

### Format Standar Penamaan File:
Gunakan format nama file yang seragam:
```text
<nama_aplikasi>_<jenis_data>_<tanggal_ekspor>.sql

Contoh yang benar:
- layanan_aduan_20261119.sql
- persuratan_transaksi_surat_20261119.sql
- perizinan_data_dummy_20261119.sql
```

### Format Pesan Handover ke Admin GitOps:
Kirimkan pesan melalui jalur komunikasi resmi (WhatsApp internal / Google Drive kedinasan):

```text
Halo Tim GitOps Diskominfo,

Mohon bantuan untuk melakukan import data ke server VM Development untuk aplikasi:
- Nama Aplikasi : [Nama Aplikasi, misal: Layanan Pengaduan / Persuratan]
- Repositori    : Diskominfo-Landak/[nama-repo] (branch development)
- File SQL      : [nama_file].sql (dikirim via link GDrive internal kedinasan)
- Jenis Ekspor  : Skenario A (Data-Only, tabel layanan_aduan & riwayat_aduan)
- Catatan Khusus: Tidak menyertakan tabel users/roles karena sudah ada seeder di server. Data warga sudah disanitasi dummy.

Terima kasih.
```

---

## 8. Studi Kasus Nyata: Migrasi Data Inputan Transaksi Aplikasi OPD

Sebagai gambaran nyata alur integrasi data:
1. Server VM Development telah terpasang seeder bawaan: 59 Unit Kerja / OPD Landak, modul sistem, hak akses, dan akun superadmin.
2. Developer telah menginput puluhan data transaksi operasional di laptop lokal (misal di database `db_aplikasi_lokal`), seperti data `layanan_aduan` dan `riwayat_aduan`.
3. Developer mengekspor data menggunakan:
   ```bash
   mysqldump -u root -p --no-create-info --insert-ignore --complete-insert db_aplikasi_lokal layanan_aduan riwayat_aduan > aduan_transaksi.sql
   ```
4. Admin GitOps mengimpor file tersebut ke server:
   - Seluruh data transaksi permohonan masuk 100%.
   - Data akun superadmin dan master 59 OPD yang sudah ada di server **sama sekali tidak rusak atau tertimpa**.
   - Integritas data diverifikasi menggunakan `php artisan tinker` dan dinyatakan valid sempurna!
