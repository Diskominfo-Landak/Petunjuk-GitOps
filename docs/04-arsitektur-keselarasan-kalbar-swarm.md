# Arsitektur Keselarasan GitOps Pemkab Landak & Panduan Docker Swarm

Dokumen ini disusun sebagai lampiran teknis dan justifikasi arsitektur dalam penyusunan **Keputusan Bupati Landak (KepBup)** tentang Pedoman Pembangunan, Pengembangan, dan Pengelolaan Aplikasi SPBE di Lingkungan Pemerintah Kabupaten Landak, dengan merujuk pada standar dan praktik baik Pemerintah Provinsi Kalimantan Barat.

---

## 1. Latar Belakang & Keselarasan dengan Pemprov Kalbar

Pemerintah Provinsi Kalimantan Barat melalui Diskominfo Provinsi telah merintis penerapan GitOps dengan repositori rujukan `Diskominfo-Kalbar/petunjuk-gitops`. Diskominfo Kabupaten Landak menyelaraskan arah kebijakan teknologi SPBE dengan Pemprov Kalbar, sekaligus melakukan penyempurnaan teknis sesuai dengan kondisi faktual infrastruktur, keamanan siber, dan kebutuhan operasional di Pemkab Landak.

### Tabel Komparasi Arsitektur:

| Aspek Arsitektur | Baseline Pemprov Kalbar | Implementasi Pemkab Landak | Justifikasi Teknis Pemkab Landak |
|---|---|---|---|
| **Orkestrator Kontainer** | Docker Swarm (Single-Node, `docker stack deploy`) | Docker Compose v2 (Satu VM per Lingkungan) | Karena node Swarm berjalan di 1 server (single-node), fungsionalitasnya setara dengan Compose. Compose jauh lebih sederhana, minim *overhead*, serta mempermudah debugging bagi tim teknis OPD pemula. |
| **Mekanisme Runner CI** | GitHub Actions Self-Hosted Runner di jaringan lokal | Runner Resmi GitHub Cloud (`ubuntu-24.04`) | Menghindari risiko keamanan injeksi skrip berbahaya pada runner internal, serta tidak membebani komputasi server lokal saat proses build image. |
| **Container Registry** | Private Docker Registry lokal (`10.10.11.93:5000`) | GitHub Container Registry (`ghcr.io/diskominfo-landak`) | Menyediakan caching lapisan container global, ketersediaan tinggi (HA), terintegrasi dengan audit trail GitHub, dan saat ini gratis untuk instansi. |
| **Manajemen Rahasia / Secrets** | `--build-arg` (kredensial tertanam di layer image) | Runtime `.env` di Server Target (`chmod 600`) | **Sangat Krusial:** Mencegah password database dan secret bocor di dalam artefak image Docker. Image container murni berisi kode biner aplikasi. |
| **Alur Deploy Development** | Didorong otomatis oleh runner internal | VM Dev menarik otomatis (`update-dev.sh` via cron) | Model penarikan (*pull*) tidak membutuhkan pembukaan port inbound SSH dari internet ke VM development, sehingga VM tetap aman di balik VPN/jaringan privat. |
| **Alur Deploy Production** | Deploy otomatis via pipeline | Manual Terkontrol (`release.sh` + Auto-Rollback) | Menghormati pemisahan wewenang (RACI): verifikasi kode oleh Tim Aplikasi, eksekusi rilis oleh Network Administrator. Dilengkapi uji kesehatan (*healthcheck*) dan *auto-rollback* otomatis jika gagal. |

---

## 2. Peta Jalan Transisi ke Docker Swarm Multi-Node

Implementasi Docker Compose saat ini didesain agar **100% siap ditransformasikan ke Docker Swarm** apabila di kemudian hari Pemkab Landak telah memiliki infrastruktur server multi-node (klaster server fisik dengan worker nodes redundan):

1. **Format File**: Konfigurasi `compose.yaml` yang kita gunakan sudah mengadopsi skema Compose Spec modern yang kompatibel dengan atribut Swarm `deploy:`.
2. **Kesiapan Stateless**: Aplikasi yang dikembangkan di lingkungan Pemkab Landak diwajibkan *stateless*, sehingga siap diskalakan (*scaling*) ke banyak replika kontainer.
3. **Penyimpanan Terpusat**: Saat klaster multi-node tersedia, volume lokal cukup dialihkan ke NFS terpusat atau Object Storage (MinIO).

---

## 3. Lampiran: Contoh Konfigurasi Docker Swarm (`stack.yaml.example`)

Jika regulasi provinsi atau kebutuhan klaster mengharuskan penggunaan `docker stack deploy`, berikut adalah contoh berkas konfigurasi Docker Swarm yang siap digunakan:

```yaml
# stack.yaml.example - Konfigurasi Docker Swarm Pemkab Landak
version: '3.8'

services:
  app:
    image: ghcr.io/diskominfo-landak/nama-aplikasi:${IMAGE_TAG:-latest}
    env_file: .env
    environment:
      RUN_MIGRATIONS: "true"
    networks:
      - internal-net
      - api-net
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
        failure_action: rollback
      rollback_config:
        parallelism: 1
        order: stop-first

  web:
    image: nginx:1.27-alpine
    configs:
      - source: nginx_conf
        target: /etc/nginx/conf.d/default.conf
    ports:
      # Pada Swarm, gunakan mode: host jika ingin membatasi bind ke 127.0.0.1
      - target: 80
        published: 8082
        protocol: tcp
        mode: host
    networks:
      - internal-net
      - api-net
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        order: start-first
        failure_action: rollback

  db:
    image: mysql:8.4
    environment:
      MYSQL_DATABASE: ${DB_DATABASE}
      MYSQL_USER: ${DB_USERNAME}
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    volumes:
      - db-data:/var/lib/mysql
    networks:
      - internal-net
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager

configs:
  nginx_conf:
    file: ./docker/nginx.conf

networks:
  internal-net:
    driver: overlay
  api-net:
    external: true
    name: api-net

volumes:
  db-data:
```

### Perintah Operasional di Docker Swarm:

```bash
# 1. Inisialisasi Swarm di server manager (cukup sekali):
docker swarm init

# 2. Buat jaringan overlay bersama untuk komunikasi antar stack:
docker network create --driver overlay --attachable api-net

# 3. Jalankan atau perbarui stack aplikasi:
docker stack deploy -c stack.yaml nama-aplikasi

# 4. Memantau status service dan replika:
docker stack services nama-aplikasi
docker service ls
```

---

## 4. Kesimpulan untuk Kebijakan Daerah (KepBup Landak)

1. **Standardisasi Berbasis Hasil**: Fokus utama KepBup adalah memastikan setiap aplikasi dibangun menggunakan kontainer Docker, lulus audit keamanan dependensi, tidak menanam password di source code, dan memiliki healthcheck terstandarisasi.
2. **Fleksibilitas Orkestrasi**: Penggunaan Docker Compose v2 diakui sah dan resmi untuk lingkungan single-VM, dengan Docker Swarm sebagai opsi ekspansi (*scale-out*) saat kebutuhan redundansi perangkat keras terpenuhi.
