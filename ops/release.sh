#!/bin/bash
# ==============================================================================
# release.sh: Pemasang Rilis Versi Produksi (Production Deployment)
# ==============================================================================
# Memasang image versi bernomor (SemVer, misal: 1.0.3) ke lingkungan PRODUCTION.
# Dilengkapi validasi tag yang benar-benar aktif, pengecekan kesehatan (healthcheck),
# dan rollback otomatis ke versi sebelumnya jika deployment gagal.
#
# Contoh Pemakaian:
#   bash release.sh referensi=1.0.3 gateway=1.0.1
#   bash release.sh finda=2.1.0
#   bash release.sh referensi=1.0.3 --skip-git
#
# Catatan: Skrip ini dijalankan oleh Network Administrator / Tim Ops di VM Production.
# ==============================================================================

set -u

unset IMAGE_TAG

APPS_DIR="${APPS_DIR:-/opt/apps}"
HEALTH_URL="${HEALTH_URL:-http://127.0.0.1:8080/up}"
HEALTH_TRIES="${HEALTH_TRIES:-36}"
HEALTH_INTERVAL="${HEALTH_INTERVAL:-5}"

SKIP_GIT=0
NEW_REF=""
NEW_GW=""

usage() {
  echo "Pemakaian: bash release.sh [referensi=X.Y.Z] [gateway=X.Y.Z] [--skip-git]"
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
    echo "ERROR: Nomor versi tidak valid: $v (Gunakan format SemVer murni: X.Y.Z, contoh: 1.0.3)"
    exit 2
  fi
done

REF_DIR="$APPS_DIR/api-referensi"
GW_DIR="$APPS_DIR/api-gateway"

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

verify_running() {
  local dir="$1" svc="$2" expected_tag="$3"
  local img
  img=$( cd "$APPS_DIR/$dir" && docker compose ps --format '{{.Image}}' "$svc" 2>/dev/null | head -n1 )
  case "$img" in
    *":$expected_tag") return 0 ;;
  esac
  echo "PERINGATAN: Service $svc berjalan dengan image '$img', bukan tag '$expected_tag'!"
  return 1
}

apply_one() {
  local dir="$1" svc="$2" tag="$3"
  set_tag "$APPS_DIR/$dir" "$tag"
  ( cd "$APPS_DIR/$dir" && docker compose pull "$svc" && docker compose up -d ) || return 1
  verify_running "$dir" "$svc" "$tag"
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

OLD_REF_TAG=$(get_tag "$REF_DIR")
OLD_GW_TAG=$(get_tag "$GW_DIR")
PREV_REF_GIT=""
PREV_GW_GIT=""

rollback() {
  echo ">>> MEMULAI ROLLBACK OTOMATIS KE VERSI SEBELUMNYA..."
  if [ "$SKIP_GIT" -eq 0 ]; then
    [ -n "$PREV_REF_GIT" ] && ( cd "$REF_DIR" && git checkout -q "$PREV_REF_GIT" )
    [ -n "$PREV_GW_GIT" ] && ( cd "$GW_DIR" && git checkout -q "$PREV_GW_GIT" )
  fi
  [ -n "$NEW_REF" ] && apply_one api-referensi app "$OLD_REF_TAG"
  [ -n "$NEW_GW" ] && apply_one api-gateway gateway "$OLD_GW_TAG"
}

# 1. Update kode konfigurasi ke tag rilis (jika tidak --skip-git)
if [ "$SKIP_GIT" -eq 0 ]; then
  if [ -n "$NEW_REF" ]; then
    PREV_REF_GIT=$(cd "$REF_DIR" 2>/dev/null && git rev-parse HEAD)
    ( cd "$REF_DIR" && git fetch --tags -q && git checkout -q "v$NEW_REF" ) || {
      echo "GAGAL: Tag Git v$NEW_REF tidak ditemukan di $REF_DIR."
      exit 1
    }
  fi
  if [ -n "$NEW_GW" ]; then
    PREV_GW_GIT=$(cd "$GW_DIR" 2>/dev/null && git rev-parse HEAD)
    ( cd "$GW_DIR" && git fetch --tags -q && git checkout -q "v$NEW_GW" ) || {
      echo "GAGAL: Tag Git v$NEW_GW tidak ditemukan di $GW_DIR."
      rollback
      exit 1
    }
  fi
fi

# 2. Pasang image baru
if [ -n "$NEW_REF" ]; then
  echo "Memasang api-referensi tag $NEW_REF ..."
  apply_one api-referensi app "$NEW_REF" || { echo "GAGAL memasang api-referensi."; rollback; exit 1; }
fi

if [ -n "$NEW_GW" ]; then
  echo "Memasang api-gateway tag $NEW_GW ..."
  apply_one api-gateway gateway "$NEW_GW" || { echo "GAGAL memasang api-gateway."; rollback; exit 1; }
fi

# 3. Pengecekan Kesehatan
echo "Memeriksa status kesehatan aplikasi ($HEALTH_URL) ..."
if healthy; then
  echo ">>> DEPLOYMENT SUKSES! Versi berjalan: api-referensi=$(get_tag "$REF_DIR"), api-gateway=$(get_tag "$GW_DIR")"
  exit 0
fi

echo ">>> DEPLOYMENT GAGAL: Aplikasi tidak merespons kesehatan dengan benar."
rollback
if healthy; then
  echo "Aplikasi berhasil dikembalikan ke versi aman sebelumnya."
else
  echo "BAHAYA: Versi sebelumnya juga gagal pulih. Cek segera: docker compose ps & logs."
fi
exit 1
