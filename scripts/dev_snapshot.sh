#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-$WORKSPACE_ROOT/_snapshots}"

usage() {
  cat <<'USAGE'
Usage: dev_snapshot.sh <command> [options]

Commands:
  freeze [label] [--with-buckets] [--with-db]
      Crea uno snapshot della workspace; può includere bucket S3 e dump Postgres.
  restore <archive> [--with-buckets] [--with-db]
      Ripristina uno snapshot e opzionalmente ripubblica bucket/DB.
  list
      Elenca gli snapshot disponibili.

Environment:
  SNAPSHOT_DIR               Directory degli snapshot (default: $WORKSPACE_ROOT/_snapshots).
  SNAPSHOT_BUCKETS           Lista bucket S3 (separati da spazio o newline).
  SNAPSHOT_BUCKETS_FILE      File con un bucket S3 per riga.
  SNAPSHOT_DB_URLS           Lista URL Postgres da dumpare/ripristinare.
  SNAPSHOT_DB_URLS_FILE      File con un URL Postgres per riga.

Examples:
  ./scripts/dev_snapshot.sh freeze
  ./scripts/dev_snapshot.sh freeze nightly --with-buckets --with-db
  ./scripts/dev_snapshot.sh list
  ./scripts/dev_snapshot.sh restore 20250924-154500-nightly.tar.gz --with-db
USAGE
}

ensure_snapshot_dir() {
  mkdir -p "$SNAPSHOT_DIR"
}

resolve_archive_path() {
  local input="$1"
  if [[ -f "$input" ]]; then
    printf '%s\n' "$(cd "$(dirname "$input")" && pwd)/$(basename "$input")"
    return 0
  fi
  local candidate="$SNAPSHOT_DIR/$input"
  if [[ -f "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  return 1
}

read_config_lines() {
  local inline="${1:-}"
  local file="${2:-}"
  if [[ -n "$inline" ]]; then
    printf '%s\n' "$inline"
  fi
  if [[ -n "$file" && -f "$file" ]]; then
    cat "$file"
  fi
}

sanitize_name() {
  local input="$1"
  input="${input//[^a-zA-Z0-9_.-]/_}"
  printf '%s\n' "$input"
}

snapshot_buckets() {
  local dest="$1"
  local buckets
  buckets="$(read_config_lines "${SNAPSHOT_BUCKETS-}" "${SNAPSHOT_BUCKETS_FILE-}")"
  if [[ -z "$buckets" ]]; then
    printf '   ⚠️  Nessun bucket configurato (SNAPSHOT_BUCKETS[_FILE]). Salto.\n'
    return 0
  fi
  if ! command -v aws >/dev/null 2>&1; then
    printf 'ERROR: aws CLI non disponibile. Installa aws per usare --with-buckets.\n' >&2
    exit 1
  fi
  printf '   ⬇️  Backup S3 bucket...\n'
  mkdir -p "$dest"
  while IFS= read -r bucket; do
    [[ -z "$bucket" ]] && continue
    local safe
    safe="$(sanitize_name "$bucket")"
    printf '     • %s\n' "$bucket"
    aws s3 sync "s3://$bucket" "$dest/$safe"
  done <<< "$buckets"
}

snapshot_databases() {
  local dest="$1"
  local urls
  urls="$(read_config_lines "${SNAPSHOT_DB_URLS-}" "${SNAPSHOT_DB_URLS_FILE-}")"
  if [[ -z "$urls" ]]; then
    printf '   ⚠️  Nessun DB configurato (SNAPSHOT_DB_URLS[_FILE]). Salto.\n'
    return 0
  fi
  if ! command -v pg_dump >/dev/null 2>&1; then
    printf 'ERROR: pg_dump non trovato. Installa i client Postgres per usare --with-db.\n' >&2
    exit 1
  fi
  printf '   ⬇️  Dump database...\n'
  mkdir -p "$dest"
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    local safe
    safe="$(sanitize_name "$url")"
    printf '     • %s\n' "$url"
    pg_dump "$url" >"$dest/$safe.sql"
  done <<< "$urls"
}

restore_buckets() {
  local source="$1"
  local buckets
  buckets="$(read_config_lines "${SNAPSHOT_BUCKETS-}" "${SNAPSHOT_BUCKETS_FILE-}")"
  if [[ -z "$buckets" ]]; then
    printf '   ⚠️  Nessun bucket configurato per il restore.\n'
    return 0
  fi
  if ! command -v aws >/dev/null 2>&1; then
    printf 'ERROR: aws CLI non disponibile. Impossibile ripristinare i bucket.\n' >&2
    exit 1
  fi
  if [[ ! -d "$source" ]]; then
    printf '   ⚠️  Nessun dump bucket nello snapshot (%s).\n' "$source"
    return 0
  fi
  printf '   ⬆️  Ripubblicazione bucket...\n'
  while IFS= read -r bucket; do
    [[ -z "$bucket" ]] && continue
    local safe
    safe="$(sanitize_name "$bucket")"
    if [[ -d "$source/$safe" ]]; then
      printf '     • %s\n' "$bucket"
      aws s3 sync "$source/$safe" "s3://$bucket"
    else
      printf '     • %s (nessun dump).\n' "$bucket"
    fi
  done <<< "$buckets"
}

restore_databases() {
  local source="$1"
  local urls
  urls="$(read_config_lines "${SNAPSHOT_DB_URLS-}" "${SNAPSHOT_DB_URLS_FILE-}")"
  if [[ -z "$urls" ]]; then
    printf '   ⚠️  Nessun DB configurato per il restore.\n'
    return 0
  fi
  if ! command -v psql >/dev/null 2>&1; then
    printf 'ERROR: psql non trovato. Impossibile ripristinare i DB.\n' >&2
    exit 1
  fi
  if [[ ! -d "$source" ]]; then
    printf '   ⚠️  Nessun dump DB nello snapshot (%s).\n' "$source"
    return 0
  fi
  printf '   ⬆️  Ripristino database...\n'
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    local safe
    safe="$(sanitize_name "$url")"
    if [[ -f "$source/$safe.sql" ]]; then
      printf '     • %s\n' "$url"
      psql "$url" -f "$source/$safe.sql"
    else
      printf '     • %s (nessun dump).\n' "$url"
    fi
  done <<< "$urls"
}

freeze_snapshot() {
  local label=""
  local include_buckets=false
  local include_db=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --with-buckets)
        include_buckets=true
        ;;
      --with-db)
        include_db=true
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      --*)
        printf 'Unknown option for freeze: %s\n' "$1" >&2
        exit 1
        ;;
      *)
        if [[ -n "$label" ]]; then
          printf 'Multiple labels provided.\n' >&2
          exit 1
        fi
        label="$1"
        ;;
    esac
    shift || true
  done

  ensure_snapshot_dir
  local timestamp
  timestamp="$(date '+%Y%m%d-%H%M%S')"
  local archive_name
  if [[ -n "$label" ]]; then
    archive_name="${timestamp}-${label}.tar.gz"
  else
    archive_name="${timestamp}.tar.gz"
  fi
  local archive_path="$SNAPSHOT_DIR/$archive_name"

  local meta_dir="$WORKSPACE_ROOT/.snapshot_meta"
  rm -rf "$meta_dir"
  mkdir -p "$meta_dir"

  if $include_buckets; then
    snapshot_buckets "$meta_dir/buckets"
  fi
  if $include_db; then
    snapshot_databases "$meta_dir/databases"
  fi

  printf '📦 Creating snapshot %s\n' "$archive_path"
  tar \
    --exclude='./_snapshots' \
    --exclude='./.DS_Store' \
    -czf "$archive_path" \
    -C "$WORKSPACE_ROOT" \
    .
  printf '✅ Snapshot ready: %s\n' "$archive_path"

  rm -rf "$meta_dir"
}

restore_snapshot() {
  local archive_input=""
  local include_buckets=false
  local include_db=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --with-buckets)
        include_buckets=true
        ;;
      --with-db)
        include_db=true
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      --*)
        printf 'Unknown option for restore: %s\n' "$1" >&2
        exit 1
        ;;
      *)
        if [[ -n "$archive_input" ]]; then
          printf 'Multiple archives provided.\n' >&2
          exit 1
        fi
        archive_input="$1"
        ;;
    esac
    shift || true
  done

  if [[ -z "$archive_input" ]]; then
    printf 'ERROR: missing archive name\n' >&2
    usage
    exit 1
  fi
  local archive_path
  if ! archive_path="$(resolve_archive_path "$archive_input")"; then
    printf 'ERROR: snapshot "%s" not found (looked in %s)\n' "$archive_input" "$SNAPSHOT_DIR" >&2
    exit 1
  fi

  printf '⚠️  Restoring snapshot %s\n' "$archive_path"
  printf '    Existing files may be overwritten. Ensure you have saved or committed changes.\n'
  tar -xzf "$archive_path" -C "$WORKSPACE_ROOT"
  printf '✅ Restore completed.\n'

  local meta_dir="$WORKSPACE_ROOT/.snapshot_meta"
  if [[ -d "$meta_dir" ]]; then
    if $include_buckets; then
      restore_buckets "$meta_dir/buckets"
    fi
    if $include_db; then
      restore_databases "$meta_dir/databases"
    fi
    rm -rf "$meta_dir"
  else
    if $include_buckets || $include_db; then
      printf '⚠️  Nessuna directory .snapshot_meta trovata nello snapshot.\n'
    fi
  fi
}

list_snapshots() {
  if [[ ! -d "$SNAPSHOT_DIR" ]]; then
    printf 'No snapshots found in %s\n' "$SNAPSHOT_DIR"
    return 0
  fi
  printf 'Available snapshots in %s:\n' "$SNAPSHOT_DIR"
  find "$SNAPSHOT_DIR" -maxdepth 1 -type f -name '*.tar.gz' -print | sort -r
}

main() {
  local cmd="${1:-}"
  if [[ -z "$cmd" ]]; then
    usage
    exit 1
  fi
  shift || true

  case "$cmd" in
    freeze)
      freeze_snapshot "$@"
      ;;
    restore)
      restore_snapshot "$@"
      ;;
    list)
      list_snapshots
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      printf 'Unknown command: %s\n\n' "$cmd" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
