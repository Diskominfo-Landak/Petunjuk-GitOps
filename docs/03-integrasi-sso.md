# Panduan Integrasi Single Sign-On (SSO) Pemkab Landak

Dokumen ini menjelaskan strategi, arsitektur, dan kebijakan integrasi autentikasi terpusat (Single Sign-On / OIDC) di lingkungan Pemerintah Kabupaten Landak.

---

## 1. Arsitektur SSO Pemkab Landak

Layanan SSO Pemkab Landak memisahkan ruang lingkup pengguna ke dalam dua ranah (*realm*) terpisah demi keamanan dan kepatuhan hukum:

1. **Ranah ASN (Aparatur Sipil Negara / Pegawai)**:
   - **Identifier Utama**: **NIP (Nomor Induk Pegawai)**.
   - **Sumber Data**: Sinkronisasi data kepegawaian resmi BKPSDM.
   - **Peruntukan**: Khusus aplikasi internal kedinasan (seperti FINDA, E-Kinerja, Presensi, SIMPEG, dsb.).
2. **Ranah Publik (Masyarakat Umum)**:
   - **Identifier Utama**: **Email / Akun Terverifikasi + OTP**.
   - **Peruntukan**: Layanan publik / perizinan / pengaduan masyarakat.
   - **Kepatuhan UU PDP**: Sesuai UU Perlindungan Data Pribadi, NIK tidak dijadikan kunci password, melainkan dilindungi sebagai data profil terenkripsi di dalam server SSO.

---

## 2. Lingkungan SSO: Development vs Production

Untuk menjaga keamanan data riil kepegawaian, Pemkab Landak menyediakan dua endpoint server SSO:

| Lingkungan | Domain Endpoint | Kapan Digunakan? |
|---|---|---|
| **Development** | `https://sso-dev.landakkab.go.id` | Digunakan saat developer koding di komputer lokal (`localhost`) dan server uji VM Development. Aman untuk simulasi akun dummy dan pengujian role. |
| **Production** | `https://sso.landakkab.go.id` | Digunakan saat aplikasi resmi rilis di VM Production dengan data akun ASN nyata. |

> **Best Practice Pengembang:**
> Aplikasi cukup membaca URL SSO dari variabel environment (`SSO_BASE_URL` di file `.env`). Saat berpindah dari dev ke production, Anda **tidak perlu mengubah kodingan**, cukup ubah nilai variabel di file `.env` server fisik.

---

## 3. Batas Integrasi: Kapan Pakai SSO vs Kapan Pakai API Key?

- **Gunakan SSO (OpenID Connect / OIDC)**:
  - Khusus untuk **interaksi manusia (Human-facing applications)** saat pengguna login melalui browser web atau aplikasi mobile.
- **Gunakan API Key / Gateway Token**:
  - Khusus untuk **pertukaran data mesin ke mesin (Machine-to-Machine)** antar aplikasi/OPD (misal: Aplikasi FINDA mengambil data wilayah dari `api-referensi` via `api-gateway`).

---

## 4. Panduan Teknis Implementasi Berdasarkan Framework

Pilih panduan teknis langkah-demi-langkah sesuai dengan teknologi framework yang Anda gunakan:

- 👉 **[Panduan Integrasi SSO untuk Laravel](panduan-sso-laravel.md)** (Menggunakan Laravel Socialite).
- 👉 **[Panduan Integrasi SSO untuk CodeIgniter](panduan-sso-codeigniter.md)** (Menggunakan CodeIgniter 4 OIDC Client).
