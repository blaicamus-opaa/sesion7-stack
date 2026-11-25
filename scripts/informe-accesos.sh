#!/usr/bin/env bash
set -euo pipefail
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
INFORMES_DIR="$PROJECT_DIR/informes"
LOG_FILE="$LOG_DIR/access.log"

mkdir -p "$INFORMES_DIR"

if [ ! -f "$LOG_FILE" ]; then
  echo "Error: no existe $LOG_FILE" >&2
  exit 1
fi

LOG_HOST_DIR="$(cd "$LOG_DIR" && (pwd -W 2>/dev/null || pwd))"
INFORMES_HOST_DIR="$(cd "$INFORMES_DIR" && (pwd -W 2>/dev/null || pwd))"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
HTML_REPORT="informe_accesos_${TIMESTAMP}.html"

echo "=== RESUMEN DE ACCESOS ($LOG_FILE) ==="
echo "Total de peticiones registradas: $(wc -l < "$LOG_FILE")"
echo ""
echo "--- DistribuciÃ³n por cÃ³digo de estado HTTP ---"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr
echo ""
echo "--- Top 10 URLs solicitadas ---"
awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 10
echo ""
echo "--- Peticiones 404 y POST a wp-login.php ---"
grep -E ' (404|403) |POST /wp-login\.php' "$LOG_FILE" | tail -n 15 || true
echo ""

echo "=== GENERANDO INFORME HTML CON allinurl/goaccess ==="
docker run --rm \
  -v "$LOG_HOST_DIR:/logs:ro" \
  -v "$INFORMES_HOST_DIR:/informes" \
  allinurl/goaccess /logs/access.log --log-format=COMBINED -o "/informes/$HTML_REPORT"

ls -lh "$INFORMES_DIR/$HTML_REPORT"
