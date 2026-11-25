#!/usr/bin/env bash
set -euo pipefail
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_HOST_DIR="$(cd "$PROJECT_DIR" && (pwd -W 2>/dev/null || pwd))"
BACKUP_DIR="$PROJECT_DIR/backups"

if [ ! -f "$PROJECT_DIR/.env" ]; then
  echo "Error: no se encontrÃƒÂ³ $PROJECT_DIR/.env" >&2
  exit 1
fi

while IFS='=' read -r key val; do
  [ -z "$key" ] && continue
  case "$key" in \#*) continue ;; esac
  export "$key=$val"
done < <(tr -d '\r' < "$PROJECT_DIR/.env")

if [ "$#" -eq 1 ]; then
  DB_FILE="$BACKUP_DIR/db_${1}.sql.gz"
  WP_FILE="$BACKUP_DIR/wpcontent_${1}.tar.gz"
elif [ "$#" -eq 2 ]; then
  DB_FILE="$1"
  WP_FILE="$2"
  [ ! -f "$DB_FILE" ] && [ -f "$BACKUP_DIR/$DB_FILE" ] && DB_FILE="$BACKUP_DIR/$DB_FILE"
  [ ! -f "$WP_FILE" ] && [ -f "$BACKUP_DIR/$WP_FILE" ] && WP_FILE="$BACKUP_DIR/$WP_FILE"
else
  echo "Uso: $0 <YYYYMMDD_HHMMSS> | <db_archivo.sql.gz> <wpcontent_archivo.tar.gz>" >&2
  exit 1
fi

if [ ! -f "$DB_FILE" ] || [ ! -f "$WP_FILE" ]; then
  echo "Error: no se encuentran los archivos de copia:" >&2
  echo "  BD: $DB_FILE" >&2
  echo "  wp-content: $WP_FILE" >&2
  exit 1
fi

echo "[1/3] Verificando integridad de los archivos de copia..."
gzip -t "$DB_FILE"
gzip -t "$WP_FILE"

echo "[2/3] Restaurando base de datos $WP_DB_NAME desde $(basename "$DB_FILE")..."
gunzip -c "$DB_FILE" | docker compose --project-directory "$PROJECT_HOST_DIR" exec -T db \
  mariadb -u"$WP_DB_USER" -p"$WP_DB_PASSWORD" "$WP_DB_NAME"

echo "[3/3] Restaurando wp-content en wp_data desde $(basename "$WP_FILE") con permisos 33:33..."
WP_FILE_HOST_DIR="$(cd "$(dirname "$WP_FILE")" && (pwd -W 2>/dev/null || pwd))"
WP_FILE_BASE="$(basename "$WP_FILE")"

docker compose --project-directory "$PROJECT_HOST_DIR" run --rm --no-deps --user 0:0 -T \
  -v "$WP_FILE_HOST_DIR:/backups:ro" --entrypoint sh wpcli -c \
  "rm -rf /var/www/html/wp-content && tar -xzf \"/backups/$WP_FILE_BASE\" -C /var/www/html && chown -R 33:33 /var/www/html/wp-content"

echo "RestauraciÃƒÂ³n completada correctamente."
