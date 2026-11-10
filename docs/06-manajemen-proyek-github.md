# Panduan Manajemen Proyek & Pelacakan Tugas Tim Aplikasi (GitHub Projects & Issues)

Panduan ini ditujukan bagi Tim Aplikasi Bidang Aptika Diskominfo Pemkab Landak untuk memodernisasi tata kelola kerja tim programmer dari pembagian tugas lisan/rapat menjadi alur kerja kolaboratif visual menggunakan **GitHub Projects (Kanban Board)** dan **GitHub Issues**.

---

## 1. Mengapa Beralih ke Board Digital?

Sebelumnya, penugasan fitur dan perbaikan bug sering dibahas secara lisan atau pesan chat tanpa papan pantau (*tools board*). Pola ini kerap menimbulkan kendala:
- Tidak terlacak siapa mengerjakan apa dan sampai tahap mana progresnya.
- Laporan bug dari OPD sering terlupakan atau terselip di riwayat obrolan WhatsApp.
- Tidak ada catatan historis yang bisa dijadikan bukti dukung capaian indikator SPBE atau laporan evaluasi kinerja.

Dengan memanfaatkan **GitHub Projects** bawaan repositori:
1. **Transparan**: Seluruh tim dan pimpinan dapat melihat progres aplikasi secara *real-time*.
2. **Terhubung ke Kode**: Setiap tugas/issue terhubung langsung dengan Pull Request dan commit programmer (`Closes #12`).
3. **Gratis & Terpusat**: Terintegrasi langsung di repositori tanpa perlu tools berbayar terpisah (seperti Jira atau Trello).

---

## 2. Struktur Papan Tugas Standar (Kanban 4 Kolom)

GitOps Administrator atau Koordinator Tim Aplikasi menyiapkan Board proyek di tab **Projects** repositori dengan 4 kolom sederhana:

```text
[ 📋 Backlog ] ───> [ 🚧 In Progress ] ───> [ 🔍 Review / Test ] ───> [ ✅ Done ]
 (Daftar Rencana)     (Sedang Dikoding)     (Diuji di VM Dev)         (Rilis / Selesai)
```

1. **`📋 Backlog / To Do`**: 
   - Kumpulan seluruh ide fitur baru, permohonan modul dari OPD, atau temuan bug yang belum mulai dikerjakan.
2. **`🚧 In Progress`**:
   - Tugas yang **sedang aktif dikerjakan** oleh programmer hari ini.
   - *Aturan Emas*: Satu programmer maksimal memegang 1-2 kartu *In Progress* secara bersamaan agar tetap fokus tuntas.
3. **`🔍 Review / Test`**:
   - Kode sudah selesai dibuat dan sudah di-push ke branch `development`.
   - Sedang ditinjau oleh GitOps Administrator atau sedang diuji coba fungsinya di domain development (`*-dev.landakkab.go.id`).
4. **`✅ Done`**:
   - Fitur atau perbaikan bug telah lulus uji dan berhasil digabungkan (*merge*) ke branch `main`.

---

## 3. Tata Kelola Pelaporan Tugas Menggunakan GitHub Issues

Setiap pekerjaan (baik penambahan modul maupun perbaikan error) wajib dibuatkan **Issue** terlebih dahulu:

### A. Cara Membuat Issue Baru:
1. Buka repositori aplikasi di GitHub $\to$ klik tab **Issues** $\to$ klik tombol hijau **New issue**.
2. Berikan **Judul yang Spesifik**:
   - Format Fitur: `[FEAT] Tambah modul filter laporan per kecamatan`
   - Format Bug: `[BUG] Tombol cetak PDF di halaman surat tugas error 500`
3. Isi deskripsi dengan informasi yang jelas:
   - Apa yang diharapkan?
   - Langkah mereproduksi error (jika pelaporan bug).
   - Lampirkan screenshot error jika ada.
4. **Tetapkan Penanggung Jawab (Assignee)**:
   - Pilih programmer yang ditugaskan mengerjakan kartu tersebut di menu *Assignees*.
5. **Beri Label**:
   - `bug` : Untuk perbaikan error/kesalahan sistem.
   - `enhancement` : Untuk penambahan fitur baru atau perbaikan tampilan.
   - `documentation` : Untuk penulisan panduan pengguna atau dokumen teknis.
   - `priority:high` : Untuk kendala mendesak yang mengganggu pelayanan dinas.

---

## 4. Alur Kerja Harian Programmer (Dari Koding sampai Selesai)

1. **Ambil Tugas**:
   - Buka Board Projects $\to$ pilih kartu Issue yang ditugaskan kepada Anda $\to$ geser kartu dari kolom **Backlog** ke **In Progress**.
2. **Koding & Buat Branch**:
   - Buat branch lokal dengan menyertakan nomor Issue:
     ```bash
     git checkout -b feat/12-modul-filter
     ```
3. **Menghubungkan Commit dengan Issue**:
   - Saat membuat commit atau Pull Request, gunakan kata kunci penutup otomatis:
     ```bash
     git commit -m "feat: tambah filter per kecamatan (Closes #12)"
     ```
   - *Keajaiban GitHub*: Begitu Pull Request Anda di-merge ke branch `main`, Issue `#12` dan kartu di Board akan **secara otomatis berpindah ke kolom Done dan ditutup (Closed)** tanpa perlu dipindah manual!
4. **Pindahkan ke Kolom Review**:
   - Saat Anda membuat PR dari branch kerja Anda ke `development`, geser kartu ke kolom **Review / Test**.
   - Beritahu GitOps Administrator untuk dilakukan peninjauan kode.

---

## 5. Sinkronisasi Rutin Tim (Stand-up Singkat 10 Menit)

Alih-alih rapat panjang berjam-jam, Tim Aplikasi Diskominfo Landak dapat menerapkan **Daily Stand-up** singkat (cukup 5-10 menit, bisa via tatap muka pagi hari atau chat tim):

Setiap programmer cukup menjawab 3 hal sambil melihat Board GitHub Projects:
1. *"Apa tugas yang sudah saya selesaikan kemarin?"*
2. *"Apa kartu yang akan saya kerjakan hari ini?"*
3. *"Apakah ada kendala teknis (blocker) yang menghambat pekerjaan saya?"*
