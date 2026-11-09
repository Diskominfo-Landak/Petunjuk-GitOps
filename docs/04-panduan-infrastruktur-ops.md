# Panduan Network Administrator & Infrastruktur (Tim Operasional Server)

Panduan ini ditujukan bagi Tim Infrastruktur / Network Administrator dalam menyiapkan VM, reverse proxy, konfigurasi auto-update di VM Development, serta prosedur eksekusi rilis ke VM Production.

---

## 1. Topologi Jaringan & Peran VM

1. **VM Development (`api-dev.landakkab.go.id`)**:
   - Berada di jaringan internal / VPN Diskominfo (`10.20.10.10`).
   - Berfungsi sebagai server pengujian fitur harian.
   - Menggunakan mekanisme **Pull Otomatis** (cron tiap 5 menit) untuk menarik image `:development` dari GHCR.
2. **VM Production (`api.landakkab.go.id` / `*.landakkab.go.id`)**:
   - Berada di segmen jaringan produksi yang terisolasi.
   - Pemasangan versi dilakukan secara **Manual Terkontrol** menggunakan skrip `release.sh`.
   - Menggunakan image dengan tag rilis bernomor (SemVer, misal: `1.0.3`).
3. **Proxy Depan (Reverse Proxy Utama)**:
   - Menterminasi SSL/TLS sertifikat HTTPS.
   - Meneruskan trafik port 80/443 ke port internal container aplikasi (misal `127.0.0.1:8080` untuk gateway, atau `127.0.0.1:808X` untuk web apps).

---

## 2. Persiapan Awal di Server (Setup VM)

Di setiap VM (Dev & Production), lakukan langkah instalasi dasar:

```bash
# 1. Pastikan Docker dan Docker Compose plugin terpasang:
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2 curl git

# 2. Tambahkan user ke group docker:
sudo usermod -aG docker $USER

# 3. Buat direktori aplikasi bersama:
sudo mkdir -p /opt/apps/ops
sudo chown -R $USER:$USER /opt/apps

# 4. Buat Docker Network bersama (api-net) jika ada layanan yang berkomunikasi internal:
docker network create api-net 2>/dev/null || true

# 5. Login ke GitHub Container Registry (GHCR):
# Gunakan Personal Access Token (PAT) akun layanan organisasi dengan scope `read:packages`
echo "TOKEN_GITHUB" | docker login ghcr.io -u "USERNAME_SERVICE_ACCOUNT" --password-stdin
```

---

## 3. Konfigurasi Auto-Update di VM Development

Salin skrip `ops/update-dev.sh` ke `/opt/apps/ops/update-dev.sh` di VM Development.

Pasang cron job agar VM menarik image terbaru secara berkala:
```bash
crontab -e
```
Tambahkan baris berikut:
```cron
# Tarik pembaruan image development tiap 5 menit
*/5 * * * * /bin/bash /opt/apps/ops/update-dev.sh
```

Untuk memantau log aktivitas pembaruan:
```bash
tail -f /opt/apps/update.log
```

---

## 4. Prosedur Rilis Produksi (Production Deployment)

Salin skrip `ops/release.sh` ke `/opt/apps/ops/release.sh` di VM Production.

Ketika Tim Pengembang memberitahukan adanya rilis baru (misal: rilis `1.0.3`), Network Administrator cukup menjalankan:

```bash
cd /opt/apps/ops

# Contoh memasang satu layanan:
bash release.sh referensi=1.0.3

# Contoh memasang beberapa layanan sekaligus:
bash release.sh referensi=1.0.3 gateway=1.0.1
```

### Mekanisme Keamanan Rilis:
1. Skrip akan memverifikasi apakah format versi valid (SemVer).
2. Skrip memperbarui tag di file `.env`, lalu menarik image dari `ghcr.io`.
3. Skrip memeriksa apakah container yang benar-benar aktif cocok dengan tag yang diminta.
4. Skrip melakukan pengujian kesehatan (*healthcheck*) ke URL target.
5. **Rollback Otomatis:** Jika dalam waktu tertentu aplikasi gagal merespons, skrip akan **secara otomatis mengembalikan container ke versi lama yang stabil** tanpa campur tangan manual.

---

## 5. Prosedur Backup Database Harian

Untuk database container yang berjalan di VM, pasang cron job backup berkala ke folder `/opt/backups`:

```bash
mkdir -p /opt/backups

# Tambahkan ke crontab (setiap pukul 02:00 malam):
0 2 * * * docker compose -f /opt/apps/api-referensi/compose.yaml exec -T db mysqldump -u root -p$(grep DB_ROOT_PASSWORD /opt/apps/api-referensi/.env | cut -d= -f2) --all-databases | gzip > /opt/backups/db-$(date +\%F).sql.gz

# Hapus backup yang lebih lama dari 14 hari:
0 3 * * * find /opt/backups -type f -name "*.sql.gz" -mtime +14 -delete
```
