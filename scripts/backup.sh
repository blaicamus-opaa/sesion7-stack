#!/usr/bin/env bash
set -euo pipefail
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_HOST_DIR="$(cd "$PROJECT_DIR" && (pwd -W 2>/dev/null || pwd))"
BACKUP_DIR="$PROJECT_DIR/backups"
mkdir -p "$BACKUP_DIR"
BACKUP_HOST_DIR="$(cd "$BACKUP_DIR" && (pwd -W 2>/dev/null || pwd))"

if [ ! -f "$PROJECT_DIR/.env" ]; then
  echo "Error: no se encontrÃƒÂ³ $PROJECT_DIR/.env" >&2
  exit 1
fi

while IFS='=' read -r key val; do
  [ -z "$key" ] && continue
  case "$key" in \#*) continue ;; esac
  export "$key=$val"
done < <(tr -d '\r' < "$PROJECT_DIR/.env")

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
DB_BACKUP="$BACKUP_DIR/db_${TIMESTAMP}.sql.gz"
WP_BACKUP="$BACKUP_DIR/wpcontent_${TIMESTAMP}.tar.gz"

echo "[1/4] Generando volcado comprimido de la base de datos ($WP_DB_NAME)..."
docker compose --project-directory "$PROJECT_HOST_DIR" exec -T db \
  mariadb-dump --single-transaction -u"$WP_DB_USER" -p"$WP_DB_PASSWORD" "$WP_DB_NAME" \
  | gzip -9 > "$DB_BACKUP"

echo "[2/4] Generando copia comprimida de wp-content desde el volumen wp_data..."
docker compose --project-directory "$PROJECT_HOST_DIR" run --rm --no-deps --user 0:0 -T \
  -v "$BACKUP_HOST_DIR:/backups" --entrypoint sh wpcli -c \
  "tar -czf /backups/wpcontent_${TIMESTAMP}.tar.gz -C /var/www/html wp-content"

echo "[3/4] Verificando integridad con gzip -t..."
gzip -t "$DB_BACKUP"
gzip -t "$WP_BACKUP"
echo "Integridad OK: $(basename "$DB_BACKUP") y $(basename "$WP_BACKUP")"

echo "[4/4] Aplicando rotaciÃƒÂ³n (conservando las 7 copias mÃƒÂ¡s recientes)..."
ls -1t "$BACKUP_DIR"/db_*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm -f
ls -1t "$BACKUP_DIR"/wpcontent_*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm -f

ls -lh "$DB_BACKUP" "$WP_BACKUP"
