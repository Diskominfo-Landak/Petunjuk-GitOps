# Panduan Integrasi Single Sign-On (SSO) Keycloak Pemkab Landak

Dokumen ini menjelaskan strategi integrasi aplikasi OPD ke server SSO (Keycloak) Pemkab Landak (`sso-dev.landakkab.go.id` / `sso.landakkab.go.id`).

---

## 1. Arsitektur SSO Pemkab Landak

Pemkab Landak memisahkan ruang lingkup pengguna ke dalam dua realm Keycloak terpisah:

1. **Realm `asn` (Aparatur Sipil Negara / Pegawai)**:
   - Identifier utama: **NIP (Nomor Induk Pegawai)**.
   - Sinkronisasi dengan data kepegawaian BKPSDM.
   - Digunakan untuk aplikasi internal kedinasan (seperti FINDA, E-Kinerja, dsb.).
2. **Realm `publik` (Masyarakat Umum)**:
   - Identifier utama: **Email / Akun Terverifikasi + OTP**.
   - Untuk mematuhi UU Pelindungan Data Pribadi (UU PDP), NIK tidak dijadikan password melainkan data profil yang terisolasi dan dilindungi di dalam Keycloak.

---

## 2. Batas Integrasi: Kapan Pakai SSO vs Kapan Pakai API Key?

- **Gunakan SSO (Keycloak / OIDC)**:
  - Khusus untuk **interaksi manusia (Human-facing applications)** saat login melalui browser atau aplikasi mobile.
- **Gunakan API Key / Gateway Token**:
  - Untuk **pertukaran data mesin ke mesin (Machine-to-Machine)** antar aplikasi/OPD (misal: Aplikasi FINDA mengambil data wilayah dari `api-referensi` via `api-gateway`).

---

## 3. Implementasi di Aplikasi Laravel (Menggunakan Laravel Socialite)

Aplikasi Laravel dapat dengan mudah diintegrasikan menggunakan paket resmi Socialite dan provider Keycloak.

### A. Instalasi Dependensi
```bash
composer require laravel/socialite socialiteproviders/keycloak
```

### B. Konfigurasi Service (`config/services.php`)
```php
'keycloak_asn' => [
    'base_url' => env('KEYCLOAK_ASN_BASE_URL', 'https://sso-dev.landakkab.go.id'),
    'client_id' => env('KEYCLOAK_ASN_CLIENT_ID'),
    'client_secret' => env('KEYCLOAK_ASN_CLIENT_SECRET'),
    'redirect' => env('KEYCLOAK_ASN_REDIRECT_URI', 'https://aplikasi.landakkab.go.id/auth/callback'),
    'realms' => env('KEYCLOAK_ASN_REALM', 'asn'),
],
```

### C. Alur Controller
1. **Redirect ke Keycloak**:
   ```php
   public function redirectToSSO() {
       return Socialite::driver('keycloak')->scopes(['openid', 'profile', 'email'])->redirect();
   }
   ```
2. **Callback Handler**:
   ```php
   public function handleSSOCallback() {
       $ssoUser = Socialite::driver('keycloak')->user();
       
       // NIP biasanya berada di nickname atau preferred_username
       $nip = $ssoUser->nickname ?? $ssoUser->user['preferred_username'];
       
       $user = User::firstOrCreate(
           ['nip' => $nip],
           [
               'name' => $ssoUser->name,
               'email' => $ssoUser->email,
               'password' => bcrypt(str()->random(32)),
           ]
       );
       
       Auth::login($user);
       return redirect('/dashboard');
   }
   ```
