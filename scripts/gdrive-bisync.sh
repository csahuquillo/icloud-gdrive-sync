#!/bin/bash
# =============================================================================
# gdrive-bisync.sh — Sincronización bidireccional iCloud ↔ Google Drive
#                    Bidirectional sync between iCloud Drive and Google Drive
#
# Uso / Usage:
#   ./gdrive-bisync.sh              # sync normal
#   ./gdrive-bisync.sh --resync     # primera vez o tras interrupción
#
# Requisitos / Requirements:
#   - rclone instalado y configurado con un remote llamado 'gdrive'
#   - rclone installed and configured with a remote named 'gdrive'
#
# Logs: /tmp/rclone-bisync.log
# =============================================================================
set -u

RCLONE=/opt/homebrew/bin/rclone   # Ajusta si rclone está en otra ruta
                                   # Adjust if rclone is in a different path

# Carpeta de iCloud a sincronizar / iCloud folder to sync
ICLOUD="/Users/$(whoami)/Library/Mobile Documents/com~apple~CloudDocs/Documents"

# Archivo de log / Log file
LOG=/tmp/rclone-bisync.log
STAMP="$(date '+%Y/%m/%d %H:%M:%S')"

log() {
  printf '%s %s\n' "$STAMP" "$*" >> "$LOG"
}

network_ready() {
  /usr/bin/nc -G 5 -z oauth2.googleapis.com 443 >/dev/null 2>&1 &&
    /usr/bin/nc -G 5 -z www.googleapis.com 443 >/dev/null 2>&1
}

# Evita ejecuciones simultáneas / Prevent concurrent runs
pgrep -x rsync > /dev/null && exit 0
pgrep -f "[r]clone bisync" > /dev/null && exit 0

# Evita arrancar bisync sin red/DNS: rclone aborta a medias si pierde acceso a
# Google durante el listado. Esto no es un fallo real de sincronización.
# Avoid starting bisync without network/DNS: rclone may abort mid-listing if it
# cannot reach Google. This is not a real sync failure.
if ! network_ready; then
  log "NOTICE: gdrive-bisync skipped: Google APIs not reachable; probably offline or captive network."
  exit 0
fi

# Ejecuta bisync / Run bisync
#
# Política de borrados / Deletion policy:
#   - Los borrados son AUTORITATIVOS en ambos lados. Si borras un fichero en
#     iCloud, se borra en Drive en la próxima ejecución (y viceversa). Sin
#     restauraciones "por seguridad".
#   - Deletions are AUTHORITATIVE on both sides. If you delete a file in
#     iCloud, it gets deleted in Drive on the next run (and vice versa).
#     No "safety" restorations.
#
# Salvaguarda anti-desastre / Anti-disaster safeguard:
#   --check-access busca un fichero canario `RCLONE_TEST` en cada lado. Si
#   no aparece (señal de que ese lado está vacío por error, no por intención),
#   bisync ABORTA sin tocar nada. Crear el marker UNA VEZ con:
#     touch "$ICLOUD/RCLONE_TEST"
#     rclone touch gdrive:RCLONE_TEST
#   --check-access looks for a canary file `RCLONE_TEST` on each side. If
#   missing (signals that side is empty by error, not intent), bisync ABORTS
#   without touching anything. Create marker ONCE with the commands above.
"$RCLONE" bisync gdrive: "$ICLOUD" \
  --drive-skip-shortcuts \
  --create-empty-src-dirs \
  --resilient \
  --check-access \
  --max-delete 9999 \
  --conflict-resolve newer \
  --log-file "$LOG" \
  --log-level INFO \
  --exclude "node_modules/**" \
  --exclude ".git/**" \
  --exclude ".DS_Store" \
  --exclude "__pycache__/**" \
  --exclude "*.pyc" \
  --exclude "Projects/**" \
  --exclude "Codex/**" \
  --exclude "Claude/**" \
  --exclude "Alta Cliente/**" \
  --exclude ".venv/**" \
  --exclude "venv/**" \
  --exclude "*.bak" \
  --exclude "*.bak.*" \
  --exclude "*.tmp" \
  --exclude "*.swp" \
  "$@"
