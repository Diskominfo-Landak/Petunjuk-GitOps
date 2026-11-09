#!/bin/bash
# ==============================================================================
# update-dev.sh: Penarik Image Otomatis untuk Lingkungan DEVELOPMENT (VM Dev)
# ==============================================================================
# Dijalankan secara berkala oleh cron (misal tiap 5 menit).
# Menarik image terbaru (:development) dari ghcr.io untuk SEMUA proyek yang terdaftar,
# dan merestart container HANYA jika image baru terdeteksi. Aman diulang.
#
# Pasang di crontab VM:
# */5 * * * * /bin/bash /opt/apps/ops/update-dev.sh
# ==============================================================================

set -u

# Pastikan variabel IMAGE_TAG di shell tidak menimpa file .env
unset IMAGE_TAG

APPS_DIR="${APPS_DIR:-/opt/apps}"
LOGFILE="${LOGFILE:-$APPS_DIR/update.log}"
LOCKFILE="${LOCKFILE:-/tmp/api-update.lock}"

log() {
  echo "$(date '+%F %T') $*" >> "$LOGFILE"
}

# $1 = nama folder/proyek, $2 = nama service di compose.yaml
update_project() {
  local dir="$APPS_DIR/$1"
  local svc="$2"
  local out

  if [ ! -d "$dir" ]; then
    log "LEWAT: Folder $dir tidak ditemukan."
    return 0
  fi

  cd "$dir" || return 1

  # Perbarui file konfigurasi & compose dari Git jika ada commit baru
  out=$(git pull --ff-only 2>&1) || log "PERINGATAN ($1): git pull gagal: $out"

  # Tarik image service milik kita (image dependency seperti mysql/nginx tidak ikut berubah)
  out=$(docker compose pull "$svc" 2>&1) || {
    log "GAGAL ($1): Gagal menarik image $svc: $out"
    return 1
  }

  # Jalankan compose up jika ada image baru (Recreate)
  out=$(docker compose up -d --remove-orphans 2>&1) || {
    log "GAGAL ($1): Gagal menjalankan container: $out"
    return 1
  }

  case "$out" in
    *Recreate*) log "SUKSES: Proyek $1 diperbarui ke image terbaru." ;;
  esac

  return 0
}

main() {
  local fail=0

  # Cegah eksekusi ganda jika proses sebelumnya belum selesai
  exec 9>"$LOCKFILE"
  flock -n 9 || exit 0

  # ----------------------------------------------------------------------------
  # DAFTAR PROYEK YANG DIPERBARUI OTOMATIS DI VM DEV:
  # Format: update_project <nama-folder-di-opt-apps> <nama-service-di-compose>
  # ----------------------------------------------------------------------------
  update_project api-referensi app || fail=1
  update_project api-gateway gateway || fail=1

  # Tambahkan proyek aplikasi OPD lain di sini jika ada:
  # update_project finda app || fail=1

  # Bersihkan image usang agar disk VM tidak penuh
  docker image prune -f > /dev/null 2>&1

  # Batasi ukuran log agar tidak membengkak (simpan 1.000 baris terakhir)
  if [ -f "$LOGFILE" ]; then
    tail -n 1000 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
  fi

  exit "$fail"
}

main "$@"
exit 0
