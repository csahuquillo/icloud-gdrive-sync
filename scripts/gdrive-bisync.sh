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

RCLONE=/opt/homebrew/bin/rclone   # Ajusta si rclone está en otra ruta
                                   # Adjust if rclone is in a different path

# Carpeta de iCloud a sincronizar / iCloud folder to sync
ICLOUD="/Users/$(whoami)/Library/Mobile Documents/com~apple~CloudDocs/Documents"

# Archivo de log / Log file
LOG=/tmp/rclone-bisync.log

# Evita ejecuciones simultáneas / Prevent concurrent runs
pgrep -x rsync > /dev/null && exit 0
pgrep -f "rclone bisync" > /dev/null && exit 0

# Ejecuta bisync / Run bisync
$RCLONE bisync gdrive: "$ICLOUD" \
  --drive-skip-shortcuts \
  --create-empty-src-dirs \
  --resilient \
  --log-file "$LOG" \
  --log-level INFO \
  --exclude "node_modules/**" \
  --exclude ".git/**" \
  --exclude ".DS_Store" \
  --exclude "__pycache__/**" \
  --exclude "*.pyc" \
  "$@"
