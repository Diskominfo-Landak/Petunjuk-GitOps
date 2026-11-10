# Standar Keamanan Aplikasi & Praktik Pengkodean Aman (Secure Coding)

Dokumen ini memuat panduan pengkodean aman (*Secure Coding*) bagi pengembang perangkat lunak di lingkungan Pemerintah Kabupaten Landak guna mencegah kerentanan sistemik, insiden siber (seperti injeksi situs judi online dan peretasan tampilan/*defacement*), serta perlindungan data pribadi ASN dan masyarakat.

> **Catatan Koordinasi Keamanan Siber:**
> Pengujian penetrasi (*penetration test*) dan audit kerentanan formal aplikasi sebelum rilis dilakukan oleh **Seksi Persandian / Tim CSIRT Diskominfo**. Panduan ini merupakan standar wajib bagi developer di Bidang Aptika agar aplikasi telah memenuhi kaidah keamanan dasar (*security by design*) sebelum diajukan uji keamanan.

---

## 1. Pencegahan Injeksi Situs Judi Online & Web Defacement

Penyusupan konten terlarang (judi online/pornografi) pada website dan aplikasi pemerintah umumnya terjadi melalui dua celah utama: **kelemahan fitur upload berkas** dan **kredensial admin yang lemah**.

### A. Pembatasan Unggah Berkas (File Upload Security)
1. **Validasi MIME Type & Ekstensi (Bukan Hanya Ekstensi)**:
   - Dilarang keras hanya memverifikasi ekstensi file secara string (misal mengecek `.jpg`).
   - Wajib memverifikasi *magic bytes* / MIME-type sebenarnya dari berkas (`image/jpeg`, `image/png`, `application/pdf`).
2. **Larangan Ekstensi Eksekutabel**:
   - Blokir mutlak unggahan dengan ekstensi: `.php`, `.phtml`, `.php5`, `.sh`, `.exe`, `.cgi`, `.pl`, `.asp`, `.aspx`.
3. **Penyimpanan di Luar Document Root / Akses PHP Dinonaktifkan**:
   - Di dalam Nginx, folder penyimpanan berkas publik (seperti `/storage/` atau `/uploads/`) **wajib dilarang mengeksekusi file PHP**.
   - Pada Nginx template GitOps kita, aturan ini sudah terkunci:
     ```nginx
     location /storage/ {
         limit_except GET HEAD { deny all; }
         # PHP-FPM tidak akan pernah memproses file di dalam path ini
     }
     ```
4. **Pengacakan Nama Berkas (Rename File)**:
   - Jangan pernah menggunakan nama asli file dari pengguna. Ubah nama berkas menjadi UUID atau hash acak:
     ```php
     // Contoh Laravel:
     $path = $request->file('dokumen')->storeAs('berkas', Str::uuid() . '.' . $extension);
     ```

### B. Proteksi Autentikasi & Akun Administratif
1. **Wajib Menggunakan Enkripsi Password Kuat**:
   - Gunakan algoritma bawaan modern: `bcrypt` (work factor minimal 10) atau `Argon2id`.
   - **DILARANG KERAS** menggunakan `md5()`, `sha1()`, atau menyimpan password dalam bentuk teks terbuka (*plaintext*).
2. **Proteksi Brute-Force (Rate Limiting)**:
   - Batasi percobaan login maksimal 5 kali berturut-turut sebelum akun/IP dibekukan sementara (*throttling*).
3. **Pemberlakuan Multi-Factor Authentication (MFA) / SSO**:
   - Untuk dashboard aplikasi dengan hak akses tinggi, arahkan autentikasi menggunakan **SSO Keycloak** yang memiliki fitur proteksi OTP dan integrasi identitas terpusat.

---

## 2. Mitigasi Celah Keamanan Umum (OWASP Top 10)

### A. SQL Injection (Injeksi Kueri Database)
- **Wajib Parameterized Queries / Prepared Statements / ORM**:
  - Laravel (Eloquent): Seluruh kueri bawaan `Model::where()` sudah aman. Hindari `DB::raw()` jika melibatkan variabel input langsung pengguna.
  - CodeIgniter / PHP Native: Wajib menggunakan Query Binding PDO:
    ```php
    // BENAR (Aman):
    $stmt = $pdo->prepare("SELECT * FROM users WHERE nip = :nip");
    $stmt->execute(['nip' => $nip]);

    // SALAH (Rentan SQL Injection):
    $query = "SELECT * FROM users WHERE nip = '" . $_POST['nip'] . "'";
    ```

### B. Cross-Site Scripting (XSS)
- **Sanitasi Seluruh Output HTML**:
  - Pada Blade Laravel, selalu gunakan kurung ganda `{{ $data }}` yang otomatis memanggil `htmlspecialchars()`. Hindari `{!! $data !!}` kecuali untuk konten HTML terverifikasi (Rich Text Editor).
  - Pada PHP Native / CodeIgniter: Gunakan `htmlspecialchars($data, ENT_QUOTES, 'UTF-8')` atau helper `esc($data)`.

### C. Cross-Site Request Forgery (CSRF)
- Seluruh formulir aplikasi web (POST, PUT, DELETE) wajib menyertakan token CSRF (`@csrf` pada Laravel, atau `csrf_field()` pada CodeIgniter).
- Untuk API machine-to-machine, gunakan otentikasi header `X-API-Key` atau Bearer Token.

---

## 3. Perlindungan Data Pribadi (Kepatuhan UU PDP)

1. **Prinsip Hak Akses Minimum (*Least Privilege*)**:
   - Jangan menampilkan data sensitif ASN/Masyarakat (seperti NIK, Nomor HP, atau riwayat kesehatan) di endpoint publik yang tidak memerlukan autentikasi.
2. **Penyembunyian Field Sensitif di Response JSON**:
   - Pastikan field password, salt, dan token API disembunyikan dari output JSON model (misal `$hidden = ['password', 'remember_token']` pada model Laravel).
3. **Pencatatan Audit Trail (Audit Log)**:
   - Setiap aksi penambahan, perubahan, atau penghapusan data penting wajib mencatat identitas pelaku (NIP/User ID), waktu, IP address, dan ringkasan perubahan untuk kebutuhan investigasi forensik jika terjadi insiden.

---

## 4. Checklist Keamanan Sebelum Diajukan ke Seksi Persandian

Sebelum aplikasi didaftarkan untuk rilis produksi dan diajukan uji penetrasi ke Seksi Persandian:

- [ ] Seluruh kodingan telah melalui pipeline `composer audit` atau `npm audit` tanpa peringatan kerentanan berisiko *High/Critical*.
- [ ] Mode debug telah dimatikan di lingkungan pengujian (`APP_DEBUG=false` / `CI_ENVIRONMENT=production`).
- [ ] Tidak ada file `.env`, kredensial database, atau private key yang terunggah di commit Git.
- [ ] Fitur upload berkas telah diverifikasi memblokir file biner eksekutabel (.php, .sh).
- [ ] Seluruh input formulir memiliki validasi ketat (panjang string, tipe data numerik/email).
- [ ] Error sistem tidak membocorkan *database trace* atau informasi internal server ke layar pengguna.
