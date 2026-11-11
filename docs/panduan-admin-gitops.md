# Panduan GitOps Administrator (Pengelola Repositori GitHub & VM Development)

Panduan ini ditujukan bagi **GitOps Administrator** Diskominfo Pemkab Landak. Peran ini memegang wewenang penuh dalam:
1. Mengelola repositori resmi organisasi GitHub (`github.com/diskominfo-landak`) dan izin kolaborator pengembang.
2. Mengelola inisialisasi aplikasi baru di server **VM Development** (port upstream, file `.env`, cron auto-update).
3. Melakukan audit dan persetujuan (*review & merge*) **Pull Request** manual ke branch `main`.
4. Menerbitkan **Tag Rilis SemVer** resmi (`vX.Y.Z`) untuk diserahterimakan ke Network Administrator (VM Production).
5. Pemeliharaan dan kebersihan resource Docker di VM Development.

---

## 1. SOP Pembuatan Repositori & Hak Akses Developer

Sesuai dengan *Juknis Pedoman Pembangunan dan Pengembangan Aplikasi Pemkab Landak*, pengembang dilarang membuat repositori sendiri untuk aplikasi pemerintah. Repositori resmi wajib disiapkan oleh GitOps Administrator:

### Langkah-Langkah:
1. Buka formulir pembuatan repositori organisasi:
   [https://github.com/organizations/diskominfo-landak/repositories/new](https://github.com/organizations/diskominfo-landak/repositories/new)
2. **Aturan Penamaan Repositori**:
   - Nama repositori **wajib disamakan persis dengan nama subdomain resmi aplikasi** (huruf kecil semua, dipisahkan tanda strip `-`).
   - *Contoh*: Jika aplikasi direncanakan beralamat di `https://simpeg.landakkab.go.id`, maka nama repositori wajib **`simpeg`** (atau `simpeg-app`).
3. **Visibilitas Repositori**:
   - Pilih **Private** (atau Public jika aplikasi kode terbuka).
   - Biarkan kosong (jangan centang *Add README*, *.gitignore*, atau *License*, karena akan menggunakan template resmi).
4. **Menambahkan Developer (Collaborator)**:
   - Minta username GitHub developer yang bersangkutan.
   - Di halaman repositori baru, buka menu **Settings** $\to$ **Collaborators and teams** (atau **Collaborators**).
   - Klik tombol **Add people**, masukkan username GitHub developer.
   - Berikan hak akses: **`Write`** (agar developer dapat melakukan push ke branch `development` dan membuat Pull Request).
5. **Menentukan Alokasi Port Upstream**:
   - Cek tabel **Port Registry VM Development** (lihat Bab 8).
   - Tentukan 1 nomor port lokal yang belum terpakai (misal: `8082`).
6. **Informasikan Data Awal ke Developer**:
   Kirimkan informasi resmi berikut kepada pengembang:
   > - **URL Repositori**: `https://github.com/Diskominfo-Landak/<nama-repo>.git`
   > - **Branch Kerja Harian**: `development`
   > - **Alokasi Port Upstream**: `8082` (untuk diisi pada `compose.yaml` di penanda `[EDIT 3/4]`)
   > - **Domain Lingkungan Uji**: `https://<nama-repo>-dev.landakkab.go.id`

---

## 2. Inisialisasi Aplikasi Baru Perdana di VM Development

Setelah developer melakukan push perdana ke branch `development` dan pipeline CI di GitHub Actions berstatus **Hijau (Success)**, GitOps Administrator menyiapkan server VM Development:

### Langkah 1: Login SSH ke VM Development
```bash
ssh admin-gitops@10.20.10.10   # Sesuaikan user & IP VM Dev
cd /opt/apps
```

### Langkah 2: Clone Repositori di Branch `development`
```bash
git clone -b development https://github.com/Diskominfo-Landak/<nama-aplikasi>.git
cd <nama-aplikasi>
```

### Langkah 3: Siapkan File `.env` Server & Variabel Sensitif
Salin file template menjadi `.env` runtime di server:
```bash
cp .env.docker.example .env
nano .env
```

**Aturan Konfigurasi `.env` di VM Development:**
1. **Domain & Environment**:
   ```env
   APP_ENV=development
   APP_DEBUG=true
   APP_URL=https://<nama-aplikasi>-dev.landakkab.go.id
   ```
2. **Koneksi Database**:
   - `DB_HOST=db` (tetap gunakan nama service container, jangan diubah ke IP).
   - `DB_DATABASE=<nama_db>`
   - `DB_USERNAME=<nama_user>` (**dilarang `root`**).
   - `DB_PASSWORD=<password_kuat>`
   - `DB_PASSWORD_ROOT=<password_root_khusus_container_db>`
3. **Generate Kunci Aplikasi (`APP_KEY`)**:
   - Khusus aplikasi **Laravel**, buat kunci acak:
     ```bash
     echo "base64:$(openssl rand -base64 32)"
     ```
   - Masukkan hasilnya ke baris `APP_KEY=base64:...` di file `.env`.
4. **Kredensial Tambahan dari Developer**:
   - Masukkan secret API, client secret SSO, atau password superadmin awal yang diberikan developer via jalur aman.
5. **Kunci Hak Akses File**:
   ```bash
   chmod 600 .env
   ```

---

## 3. Eksekusi Container Perdana & Penanganan Database Awal

### A. Nyalakan Service Container
```bash
# Tarik image terbaru dari GHCR
docker compose pull

# Nyalakan stack container di background
docker compose up -d
```

### B. Verifikasi Kesehatan & Log Migrasi Awal
Periksa apakah seluruh service (`db`, `app`, `web`) menyala dengan sehat:
```bash
docker compose ps
docker compose logs -f app
```

### C. Penanganan Khusus Berdasarkan Framework:

1. **Aplikasi Laravel**:
   - Skrip `docker/entrypoint.sh` template kita secara otomatis mengeksekusi `php artisan migrate --force`.
   - Jika database baru pertama kali dibuat (tabel `users` masih kosong), skrip juga otomatis menjalankan seeder `php artisan db:seed --force`.
   - Jika perlu menjalankan migrasi/seeder manual:
     ```bash
     docker compose exec app php artisan migrate --force
     docker compose exec app php artisan db:seed --force
     ```

2. **Aplikasi CodeIgniter (CI 4)**:
   - Jalankan migrasi melalui container app:
     ```bash
     docker compose exec app php spark migrate
     # Jika ada seeder:
     docker compose exec app php spark db:seed DatabaseSeeder
     ```

3. **Aplikasi Legacy / Import Database SQL Manual (`.sql`)**:
   - Jika aplikasi lama membawa berkas dump database (misal `backup_awal.sql`):
     ```bash
     docker compose exec -T db mysql -u <nama_user> -p'<password>' <nama_database> < /path/ke/backup_awal.sql
     ```

---

## 4. Pendaftaran Domain Uji & Auto-Update Cron

### A. Koordinasikan Reverse Proxy ke Network Administrator
Informasikan kepada **Network Administrator** agar domain uji `https://<nama-aplikasi>-dev.landakkab.go.id` dipetakan ke port lokal container:
- **Upstream Host**: `127.0.0.1:<port_aplikasi>` (misal `127.0.0.1:8082`).
*(Lihat dokumen teknis port upstream jika tim jaringan memerlukan penjelasan).*

### B. Daftarkan Aplikasi ke Skrip Auto-Update VM Dev
Agar aplikasi di VM Development otomatis diperbarui setiap kali developer melakukan `git push` ke branch `development`, daftarkan aplikasi ke skrip cron:

1. Buka skrip `/opt/apps/ops/update-dev.sh`:
   ```bash
   nano /opt/apps/ops/update-dev.sh
   ```
2. Tambahkan baris baru pada fungsi `main()`:
   ```bash
   update_project <nama-aplikasi> app || fail=1
   ```
3. Uji jalankan skrip secara manual untuk memastikan tidak ada kesalahan:
   ```bash
   sudo bash /opt/apps/ops/update-dev.sh
   ```
4. Pastikan cronjob aktif di sistem Linux VM Dev (`crontab -e`):
   ```bash
   */5 * * * * /opt/apps/ops/update-dev.sh >> /var/log/gitops-update.log 2>&1
   ```
5. Periksa log auto-update:
   ```bash
   tail -n 30 -f /var/log/gitops-update.log
   ```

---

## 5. Pengaturan Izin Workflow & Visibilitas GHCR

### 5.1 Mengaktifkan Workflow Permissions di Organisasi
Jika pada repositori baru opsi *Workflow permissions* terkunci (*disabled* / abu-abu):
1. Buka: [https://github.com/organizations/diskominfo-landak/settings/actions](https://github.com/organizations/diskominfo-landak/settings/actions).
2. Di bagian **Workflow permissions**, pilih: **Read and write permissions**.
3. Centang: **Allow GitHub Actions to create and approve pull requests**.
4. Klik **Save**.

### 5.2 Menetapkan Visibilitas Package GHCR (Best Practice: Public)
Setelah workflow CI berjalan sukses untuk pertama kali, image akan tersimpan di tab Packages:
1. Buka [https://github.com/orgs/diskominfo-landak/packages](https://github.com/orgs/diskominfo-landak/packages).
2. Klik nama package aplikasi.
3. Di kanan bawah, klik **Package settings**.
4. Di bagian **Danger Zone**, klik **Change package visibility**.
5. Ubah menjadi **Public**.
> 💡 **Mengapa Public?** Karena seluruh repositori kita mematuhi kaidah keamanan: **sama sekali tidak ada file `.env`, kredensial, atau password di dalam image Docker**. Menjadikannya *Public* membuat server VM Dev & Production dapat melakukan `docker compose pull` selamanya tanpa risiko terhenti akibat token PAT kedaluwarsa.

---

## 6. Tata Kelola Audit Manual Pull Request (Solusi GitHub Free)

Karena organisasi menggunakan akun **GitHub Free**, fitur branch protection wajib-review otomatis tidak tersedia di repositori Private. Oleh karena itu, kita menerapkan **SOP Audit Manual PR**:

Setiap kali fitur baru selesai diuji di VM Development dan siap dinaikkan ke `main`, developer wajib mengajukan Pull Request (PR) dari `development` ke `main`.

### Checklist Audit GitOps Administrator Sebelum Merge:

Buka tab **Pull requests** $\to$ klik PR $\to$ pilih tab **Files changed**:

- [ ] ❌ **Audit Kredensial**: Pastikan **TIDAK ADA** file `.env`, `.env.backup`, file sertifikat/key (`.pem`, `.key`), atau file dump SQL (`.sql`) yang terikut ke commit.
- [ ] ❌ **Audit File Sampah**: Pastikan folder `vendor/`, `node_modules/`, `.idea/`, atau `.vscode/` tidak ikut terunggah.
- [ ] 🔍 **Audit `.env.docker.example`**: Apakah developer menambahkan variabel environment baru?
  - *Jika ada*: Salin variabel tersebut dan masukkan nilainya ke file `.env` di VM Development sebelum melakukan merge.
- [ ] 🔍 **Audit Migrasi Database**: Periksa file di `database/migrations/`. Pastikan tidak ada query destruktif tak terencana (seperti `DROP TABLE` pada tabel data utama) tanpa mekanisme backup.
- [ ] ✅ **Status CI GitHub Actions**: Pastikan icon berstatus **Centang Hijau (Success)**. Jika merah, tolak PR dan minta developer memperbaiki unit test / error build terlebih dahulu.

### Cara Menyetujui (*Merge*):
1. Kembali ke tab **Conversation**.
2. Klik tombol hijau **Merge pull request** $\to$ pilih **Create a merge commit** (atau *Squash and merge*).
3. Klik **Confirm merge**.

---

## 7. Menerbitkan Tag Rilis SemVer (Untuk Production) & Rollback

Setelah PR di-merge ke `main`, GitOps Administrator menerbitkan **Tag Rilis Resmi**:

### Cara 1: Lewat Web GitHub (Releases)
1. Buka `https://github.com/diskominfo-landak/<nama-repo>/releases`.
2. Klik **Draft a new release**.
3. Di **Choose a tag**, ketik versi SemVer baru, contoh: `v1.0.0` $\to$ klik **Create new tag: v1.0.0 on publish**.
4. Target: pastikan branch **`main`**.
5. Title: `Release v1.0.0 - Versi Perdana Stabil`.
6. Klik **Generate release notes** (agar GitHub merangkum otomatis isi PR), lalu klik **Publish release**.

### Cara 2: Lewat Terminal Git di Laptop
```bash
git checkout main
git pull origin main
git tag -a v1.0.0 -m "Release v1.0.0: Versi perdana stabil"
git push origin v1.0.0
```

### Koordinasi Serah Terima ke Network Administrator:
Hubungi Network Administrator via chat/memo:
> *"Pak Network Administrator, aplikasi `<nama-aplikasi>` sudah rilis versi `1.0.0`. Image `ghcr.io/diskominfo-landak/<nama-aplikasi>:1.0.0` sudah siap di GHCR. Mohon dieksekusi deploy ke VM Production."*

### SOP Rollback Darurat (Jika Rilis Baru Mengalami Kendala):
Jika versi `v1.1.0` yang baru dipasang di VM Production mengalami kendala fatal, instruksikan Network Administrator untuk segera melakukan rollback ke versi stabil sebelumnya:
```bash
# Di VM Production:
cd /opt/apps/ops
bash release.sh <nama-aplikasi>=1.0.0
```

---

## 8. Pemeliharaan Rutin Server VM Development

### Pembersihan Image Docker Bekas (Prune)
Karena VM Development menarik image baru setiap 5 menit (bisa puluhan kali sehari saat masa aktif pengkodean), ruang disk VM akan cepat terisi oleh image-image lama berstatus *dangling/untagged*.

Jadwalkan pembersihan otomatis mingguan via `crontab -e` di VM Development:
```bash
# Dijalankan setiap hari Minggu pukul 02.00 dini hari:
0 2 * * 0 docker image prune -af --filter "until=168h" >> /var/log/docker-prune.log 2>&1
```

---

## 9. Tabel Port Registry VM Development (Contoh Standar)

GitOps Administrator wajib memelihara buku catatan alokasi port upstream lokal di server VM Development:

| Port Internal Host | Nama Repositori | Subdomain Dev (HTTPS 443) | Keterangan Layanan |
|---|---|---|---|
| `127.0.0.1:8080` | `api-gateway` | `api-dev.landakkab.go.id` | API Gateway Sentral |
| `127.0.0.1:8081` | `finda` | `finda-dev.landakkab.go.id` | Aplikasi Pengelolaan Keuangan |
| `127.0.0.1:8082` | `simpeg` | `simpeg-dev.landakkab.go.id` | Aplikasi Kepegawaian & SDM |
| `127.0.0.1:8083` | `layanan-perizinan` | `izin-dev.landakkab.go.id` | Sistem Perizinan Terpadu |
| `127.0.0.1:8084` | `persuratan` | `surat-dev.landakkab.go.id` | Tata Naskah Dinas Elektronik |
| `127.0.0.1:8085..8099` | *(Aplikasi Baru)* | `[app]-dev.landakkab.go.id` | Alokasi dinamis berikutnya |
