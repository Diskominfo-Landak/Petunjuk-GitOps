# Panduan Integrasi SSO untuk Aplikasi CodeIgniter 4

Dokumen ini memandu pengembang aplikasi berbasis **CodeIgniter 4** dalam mengintegrasikan Single Sign-On (SSO) Pemkab Landak berbasis standar protokol **OpenID Connect (OIDC) / OAuth2**.

---

## 1. Konsep Alur OIDC di CodeIgniter 4

CodeIgniter 4 dapat berintegrasi dengan SSO Pemkab Landak melalui 2 rute controller sederhana:
1. **Redirect**: Mengarahkan browser pengguna ke URL otentikasi SSO (`/protocol/openid-connect/auth`).
2. **Callback**: Menerima `code` otentikasi dari SSO, menukarkannya dengan access token via HTTP POST (`CURLRequest`), lalu mengambil data profil pengguna (NIP, nama, email).

---

## 2. Daftarkan Variabel Environment

Tambahkan variabel konfigurasi SSO di file `.env.docker.example` root proyek Anda:

```dotenv
# Konfigurasi SSO Pemkab Landak
SSO_BASE_URL=https://sso-dev.landakkab.go.id
SSO_REALM=asn
SSO_CLIENT_ID=nama-aplikasi-ci
SSO_CLIENT_SECRET=masukkan_client_secret_disini
SSO_REDIRECT_URI=https://nama-aplikasi-dev.landakkab.go.id/auth/sso/callback
```

---

## 3. Implementasi Controller Autentikasi

Buat controller baru di: `src/app/Controllers/SSO.php`

```php
<?php

namespace App\Controllers;

use App\Controllers\BaseController;
use CodeIgniter\HTTP\ResponseInterface;

class SSO extends BaseController
{
    private string $baseUrl;
    private string $realm;
    private string $clientId;
    private string $clientSecret;
    private string $redirectUri;

    public function __construct()
    {
        $this->baseUrl      = rtrim(env('SSO_BASE_URL', 'https://sso-dev.landakkab.go.id'), '/');
        $this->realm        = env('SSO_REALM', 'asn');
        $this->clientId     = env('SSO_CLIENT_ID', '');
        $this->clientSecret = env('SSO_CLIENT_SECRET', '');
        $this->redirectUri  = env('SSO_REDIRECT_URI', site_url('auth/sso/callback'));
    }

    /**
     * Mengarahkan pengguna ke halaman login SSO Pemkab Landak
     */
    public function login(): ResponseInterface
    {
        $authUrl = "{$this->baseUrl}/realms/{$this->realm}/protocol/openid-connect/auth?" . http_build_query([
            'client_id'     => $this->clientId,
            'redirect_uri'  => $this->redirectUri,
            'response_type' => 'code',
            'scope'         => 'openid profile email',
        ]);

        return redirect()->to($authUrl);
    }

    /**
     * Menangani callback dan otentikasi akun pengguna
     */
    public function callback()
    {
        $code = $this->request->getGet('code');

        if (!$code) {
            return redirect()->to('/login')->with('error', 'Otorisasi login SSO dibatalkan.');
        }

        $client = \Config\Services::curlrequest();

        // 1. Tukar 'code' dengan Access Token
        $tokenUrl = "{$this->baseUrl}/realms/{$this->realm}/protocol/openid-connect/token";
        try {
            $tokenResponse = $client->post($tokenUrl, [
                'form_params' => [
                    'grant_type'    => 'authorization_code',
                    'client_id'     => $this->clientId,
                    'client_secret' => $this->clientSecret,
                    'redirect_uri'  => $this->redirectUri,
                    'code'          => $code,
                ],
            ]);

            $tokenData = json_decode($tokenResponse->getBody(), true);
            $accessToken = $tokenData['access_token'] ?? null;
        } catch (\Exception $e) {
            return redirect()->to('/login')->with('error', 'Gagal memproses token SSO: ' . $e->getMessage());
        }

        // 2. Ambil Profil Pengguna dari endpoint UserInfo
        $userInfoUrl = "{$this->baseUrl}/realms/{$this->realm}/protocol/openid-connect/userinfo";
        try {
            $userResponse = $client->get($userInfoUrl, [
                'headers' => [
                    'Authorization' => 'Bearer ' . $accessToken,
                ],
            ]);
            $userInfo = json_decode($userResponse->getBody(), true);
        } catch (\Exception $e) {
            return redirect()->to('/login')->with('error', 'Gagal mengambil data profil SSO.');
        }

        // NIP ASN diambil dari username atau preferred_username
        $nip = $userInfo['preferred_username'] ?? $userInfo['nickname'] ?? null;

        if (!$nip) {
            return redirect()->to('/login')->with('error', 'Data NIP tidak ditemukan pada akun SSO.');
        }

        // 3. Simpan data login ke Session CodeIgniter
        $session = session();
        $session->set([
            'isLoggedIn' => true,
            'nip'        => $nip,
            'name'       => $userInfo['name'] ?? '',
            'email'      => $userInfo['email'] ?? '',
        ]);

        return redirect()->to('/dashboard');
    }

    /**
     * Logout aplikasi dan arahkan logout dari sesi SSO terpusat
     */
    public function logout(): ResponseInterface
    {
        session()->destroy();

        $postLogoutRedirectUri = urlencode(site_url('/'));
        $logoutUrl = "{$this->baseUrl}/realms/{$this->realm}/protocol/openid-connect/logout"
            . "?client_id={$this->clientId}&post_logout_redirect_uri={$postLogoutRedirectUri}";

        return redirect()->to($logoutUrl);
    }
}
```

---

## 4. Daftarkan Rute di CodeIgniter (`src/app/Config/Routes.php`)

Tambahkan rute SSO berikut:

```php
$routes->get('auth/sso/login', 'SSO::login');
$routes->get('auth/sso/callback', 'SSO::callback');
$routes->get('auth/sso/logout', 'SSO::logout');
```
