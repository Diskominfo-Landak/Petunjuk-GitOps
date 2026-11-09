#!/bin/bash
# ==============================================================================
# release.sh: Pemasang Rilis Versi Produksi (Production Deployment)
# ==============================================================================
# Memasang VERSI TERTENTU (SemVer, misal: 1.0.3) ke lingkungan PRODUCTION,
# dilengkapi verifikasi tag container aktif, pemeriksaan kesehatan (healthcheck),
# dan pengembalian otomatis (rollback) ke branch/versi sebelumnya jika gagal.
#
# Contoh:
#   bash release.sh referensi=1.0.3 gateway=1.0.1
#   bash release.sh referensi=1.0.3
#   bash release.sh referensi=1.0.3 --skip-git
#
# Syarat: versi itu sudah dirilis di GitHub (tag v1.0.3 pada repo terkait) dan
# image-nya sudah ada di ghcr.io. Server sudah login ke ghcr.io.
#
# Catatan: skrip ini juga mengarahkan folder repo ke tag versi tersebut (git checkout),
# agar berkas compose dan konfigurasi sesuai dengan image. Jika server tidak boleh
# mengakses GitHub, salin berkas versi itu secara manual lalu jalankan --skip-git.
# ==============================================================================

set -u

# PENTING: variabel IMAGE_TAG yang ada di sesi shell (misalnya karena `set -a; . ./.env`)
# MENIMPA isi berkas .env pada docker compose. Dibuang agar yang berlaku selalu isi .env.
unset IMAGE_TAG

APPS_DIR="${APPS_DIR:-/opt/apps}"
HEALTH_URL="${HEALTH_URL:-http://127.0.0.1:8080/up}"
HEALTH_TRIES="${HEALTH_TRIES:-36}"
HEALTH_INTERVAL="${HEALTH_INTERVAL:-5}"

REF_DIR="$APPS_DIR/api-referensi"
GW_DIR="$APPS_DIR/api-gateway"

NEW_REF=""
NEW_GW=""
SKIP_GIT=0

usage() {
  echo "Pemakaian: bash release.sh referensi=X.Y.Z [gateway=X.Y.Z] [--skip-git]"
  echo "Contoh:    bash release.sh referensi=1.0.3 gateway=1.0.1"
  exit 2
}

for arg in "$@"; do
  case "$arg" in
    referensi=*) NEW_REF="${arg#referensi=}" ;;
    gateway=*)   NEW_GW="${arg#gateway=}" ;;
    --skip-git)  SKIP_GIT=1 ;;
    *) usage ;;
  esac
done

[ -n "$NEW_REF$NEW_GW" ] || usage

for v in "$NEW_REF" "$NEW_GW"; do
  if [ -n "$v" ] && ! echo "$v" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "Nomor versi tidak valid: $v (contoh yang benar: 1.0.3)"
    exit 2
  fi
done

get_tag() {
  local t
  t=$(grep -E '^IMAGE_TAG=' "$1/.env" 2>/dev/null | head -n1 | cut -d= -f2)
  echo "${t:-development}"
}

set_tag() {
  if grep -qE '^IMAGE_TAG=' "$1/.env"; then
    sed -i "s|^IMAGE_TAG=.*|IMAGE_TAG=$2|" "$1/.env"
  else
    echo "IMAGE_TAG=$2" >> "$1/.env"
  fi
}

# Posisi git saat ini: nama branch jika ada, jika tidak hash commit.
# Dipakai agar rollback kembali ke BRANCH (bukan detached HEAD), sehingga git pull tetap jalan.
git_position() {
  ( cd "$1" && { git symbolic-ref -q --short HEAD || git rev-parse HEAD; } )
}

# Memastikan image yang BENAR-BENAR berjalan bertag sesuai permintaan.
# $1 = folder, $2 = service, $3 = tag
verify_running() {
  local img
  img=$( cd "$APPS_DIR/$1" && docker compose ps --format '{{.Image}}' "$2" 2>/dev/null | head -n1 )
  case "$img" in
    *":$3") return 0 ;;
  esac
  echo "PERIKSA: service $2 berjalan dengan image '$img', padahal diminta tag '$3'."
  return 1
}

# $1 = folder, $2 = service, $3 = tag
apply_one() {
  set_tag "$APPS_DIR/$1" "$3"
  ( cd "$APPS_DIR/$1" && docker compose pull "$2" && docker compose up -d ) || return 1
  verify_running "$1" "$2" "$3"
}

healthy() {
  local i=0
  while [ "$i" -lt "$HEALTH_TRIES" ]; do
    if curl -fsS -o /dev/null "$HEALTH_URL" 2>/dev/null; then
      return 0
    fi
    i=$((i + 1))
    sleep "$HEALTH_INTERVAL"
  done
  return 1
}

# Seluruh langkah yang berjalan SETELAH git checkout ada di dalam fungsi, dipanggil di baris
# terakhir. Alasannya: git checkout dapat mengganti berkas skrip saat sedang berjalan.
main() {
  local OLD_REF_TAG OLD_GW_TAG
  OLD_REF_TAG=$(get_tag "$REF_DIR")
  OLD_GW_TAG=$(get_tag "$GW_DIR")
  PREV_REF_GIT=""
  PREV_GW_GIT=""

  rollback() {
    echo "Mengembalikan ke versi sebelumnya..."
    if [ "$SKIP_GIT" -eq 0 ]; then
      [ -n "$PREV_REF_GIT" ] && ( cd "$REF_DIR" && git checkout -q "$PREV_REF_GIT" )
      [ -n "$PREV_GW_GIT" ] && ( cd "$GW_DIR" && git checkout -q "$PREV_GW_GIT" )
    fi
    [ -n "$NEW_REF" ] && apply_one api-referensi app "$OLD_REF_TAG"
    [ -n "$NEW_GW" ] && apply_one api-gateway gateway "$OLD_GW_TAG"
  }

  # 1. Arahkan berkas konfigurasi ke tag versi (kecuali --skip-git)
  if [ "$SKIP_GIT" -eq 0 ]; then
    if [ -n "$NEW_REF" ]; then
      PREV_REF_GIT=$(git_position "$REF_DIR")
      ( cd "$REF_DIR" && git fetch --tags && git checkout -q "v$NEW_REF" ) || {
        echo "GAGAL: tag v$NEW_REF tidak bisa diambil untuk api-referensi. Tidak ada yang diubah."
        exit 1
      }
    fi
    if [ -n "$NEW_GW" ]; then
      PREV_GW_GIT=$(git_position "$GW_DIR")
      ( cd "$GW_DIR" && git fetch --tags && git checkout -q "v$NEW_GW" ) || {
        echo "GAGAL: tag v$NEW_GW tidak bisa diambil untuk api-gateway."
        rollback
        exit 1
      }
    fi
  fi

  # 2. Pasang image versi baru
  if [ -n "$NEW_REF" ]; then
    echo "Memasang api-referensi $NEW_REF ..."
    apply_one api-referensi app "$NEW_REF" || { echo "GAGAL memasang api-referensi."; rollback; exit 1; }
  fi

  if [ -n "$NEW_GW" ]; then
    echo "Memasang api-gateway $NEW_GW ..."
    apply_one api-gateway gateway "$NEW_GW" || { echo "GAGAL memasang api-gateway."; rollback; exit 1; }
  fi

  # 3. Periksa kesehatan; jika gagal, kembalikan
  echo "Memeriksa kesehatan ($HEALTH_URL) ..."
  if healthy; then
    echo "BERHASIL. Versi berjalan: api-referensi=$(get_tag "$REF_DIR"), api-gateway=$(get_tag "$GW_DIR")"
    exit 0
  fi

  echo "GAGAL: layanan tidak sehat setelah pemasangan."
  rollback
  if healthy; then
    echo "Versi sebelumnya sudah dipulihkan: api-referensi=$OLD_REF_TAG, api-gateway=$OLD_GW_TAG"
  else
    echo "PERHATIAN: versi sebelumnya pun belum sehat. Periksa dengan: docker compose ps dan docker compose logs"
  fi
  exit 1
}

main "$@"; exit $?
