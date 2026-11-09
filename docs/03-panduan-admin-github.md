# Panduan Admin GitHub Organisasi (Tim Pengelola Aplikasi)

Panduan ini ditujukan bagi Administrator GitHub Organisasi Diskominfo Pemkab Landak (`github.com/diskominfo-landak`) dalam mengelola repositori, izin akses, dan paket container registry.

---

## 1. Membuat Repositori Baru

1. Buat repositori baru di organisasi `diskominfo-landak`.
2. Pilih visibilitas **Private** (atau Public jika aplikasi kode terbuka).
3. Inisialisasi dengan branch default: `main`, lalu buat branch `development`.
4. Berikan hak akses tim pengembang:
   - **Tim Developer**: Hak akses `Write`.
   - **Lead Developer / Admin**: Hak akses `Maintain` atau `Admin`.

---

## 2. Pengaturan GitHub Container Registry (GHCR)

Image container disimpan di GitHub Packages (GHCR) di bawah namespace organisasi.

1. **Izin Package Workflow**:
   - Masuk ke menu **Settings** repositori $\to$ **Actions** $\to$ **General**.
   - Pada bagian **Workflow permissions**, pastikan opsi **Read and write permissions** aktif (agar GitHub Actions dapat mem-push image ke GHCR).
2. **Visibilitas Package GHCR**:
   - Setelah workflow CI pertama kali berjalan dan berhasil push image, package akan muncul di tab **Packages** organisasi.
   - Pastikan visibilitas package diatur sesuai kebutuhan:
     - Jika repositori Private, package secara default Private.
     - Untuk VM Production atau VM Development agar dapat menarik image, pastikan token server (Personal Access Token / PAT) atau service account organisasi memiliki scope `read:packages`.

---

## 3. Disiplin Branch & Kebijakan Review (Solusi Akun GitHub Free)

Karena organisasi saat ini menggunakan paket **GitHub Free**, fitur *Branch Protection Rules* dengan syarat wajib review PR tidak tersedia untuk repositori Private.

Sebagai gantinya, tegakkan **Kesepakatan Tata Kelola (Social Contract)**:
1. **Batasi Akses Direct Push ke `main`**:
   - Hanya Lead Developer / Admin yang diberi wewenang melakukan merge PR ke `main` dan membuat tag rilis `v*`.
   - Developer biasa dilarang melakukan `git push origin main` secara langsung.
2. **Review Manual via Pull Request**:
   - Setiap perubahan dari `development` ke `main` wajib melalui formulir Pull Request di web GitHub dengan menyertakan checklist perubahan dan changelog.
