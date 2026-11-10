# Panduan Integrasi SSO untuk Aplikasi Laravel

Dokumen ini memandu pengembang aplikasi berbasis **Laravel 11 / 12** dalam mengintegrasikan Single Sign-On (SSO) Pemkab Landak menggunakan protokol standar OpenID Connect (OIDC) melalui paket resmi **Laravel Socialite**.

---

## 1. Instalasi Dependensi

Pasang paket Laravel Socialite dan provider Keycloak/OIDC via Composer:

```bash
composer require laravel/socialite socialiteproviders/keycloak
```

---

## 2. Daftarkan Variabel Environment

Tambahkan variabel konfigurasi SSO di file `.env.docker.example` proyek Anda:

```dotenv
# Konfigurasi SSO Pemkab Landak
SSO_BASE_URL=https://sso-dev.landakkab.go.id
SSO_REALM=asn
SSO_CLIENT_ID=nama-aplikasi-anda
SSO_CLIENT_SECRET=masukkan_client_secret_disini
SSO_REDIRECT_URI=https://nama-aplikasi-dev.landakkab.go.id/auth/sso/callback
```
*(Di laptop lokal, Anda bisa mengatur `SSO_REDIRECT_URI=http://localhost:8080/auth/sso/callback`)*.

---

## 3. Konfigurasi Layanan (`config/services.php`)

Tambahkan konfigurasi SSO di file `src/config/services.php`:

```php
'sso_asn' => [
    'base_url'      => env('SSO_BASE_URL', 'https://sso-dev.landakkab.go.id'),
    'realms'        => env('SSO_REALM', 'asn'),
    'client_id'     => env('SSO_CLIENT_ID'),
    'client_secret' => env('SSO_CLIENT_SECRET'),
    'redirect'      => env('SSO_REDIRECT_URI'),
],
```

---

## 4. Implementasi Controller Autentikasi

Buat controller untuk menangani alur redirect dan callback:
`src/app/Http/Controllers/Auth/SSOController.php`

```php
<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Laravel\Socialite\Facades\Socialite;

class SSOController extends Controller
{
    /**
     * Mengarahkan pengguna ke halaman login SSO resmi Pemkab Landak
     */
    public function redirect()
    {
        return Socialite::driver('keycloak')
            ->scopes(['openid', 'profile', 'email'])
            ->redirect();
    }

    /**
     * Menangani callback setelah pengguna berhasil login di SSO
     */
    public function callback()
    {
        try {
            $ssoUser = Socialite::driver('keycloak')->user();
        } catch (\Exception $e) {
            return redirect('/login')->withErrors(['error' => 'Gagal login via SSO: ' . $e->getMessage()]);
        }

        // Pengenal utama ASN Pemkab Landak adalah NIP
        $nip = $ssoUser->nickname ?? $ssoUser->user['preferred_username'] ?? null;

        if (!$nip) {
            return redirect('/login')->withErrors(['error' => 'Data NIP tidak ditemukan pada akun SSO.']);
        }

        // Cari atau daftarkan akun user di database lokal aplikasi
        $user = User::updateOrCreate(
            ['nip' => $nip],
            [
                'name'     => $ssoUser->name,
                'email'    => $ssoUser->email ?? $nip . '@landakkab.go.id',
                'password' => bcrypt(str()->random(32)), // Random password (login murni via SSO)
            ]
        );

        // Buat sesi login aplikasi
        Auth::login($user);

        return redirect()->intended('/dashboard');
    }

    /**
     * Logout aplikasi dan arahkan logout dari sesi SSO terpusat
     */
    public function logout()
    {
        Auth::logout();
        request()->session()->invalidate();
        request()->session()->regenerateToken();

        $baseUrl  = config('services.sso_asn.base_url');
        $realm    = config('services.sso_asn.realms');
        $clientId = config('services.sso_asn.client_id');
        $postLogoutRedirectUri = url('/');

        $logoutUrl = rtrim($baseUrl, '/') . "/realms/{$realm}/protocol/openid-connect/logout";

        return redirect()->away("{$logoutUrl}?client_id={$clientId}&post_logout_redirect_uri={$postLogoutRedirectUri}");
    }
}
```

---

## 5. Daftarkan Rute Aplikasi (`src/routes/web.php`)

```php
use App\Http\Controllers\Auth\SSOController;

Route::get('/auth/sso/login', [SSOController::class, 'redirect'])->name('sso.login');
Route::get('/auth/sso/callback', [SSOController::class, 'callback'])->name('sso.callback');
Route::post('/auth/sso/logout', [SSOController::class, 'logout'])->name('sso.logout');
```
