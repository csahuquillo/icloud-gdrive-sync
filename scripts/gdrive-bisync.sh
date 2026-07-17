#!/bin/bash
# =============================================================================
# gdrive-bisync.sh — Sincronización bidireccional iCloud ↔ Google Drive
#                    Bidirectional sync between iCloud Drive and Google Drive
#
# Uso / Usage:
#   ./gdrive-bisync.sh              # sync normal / normal sync
#   ./gdrive-bisync.sh --resync     # rebaseline — lee la REGLA DE ORO / read the GOLDEN RULE
#
# -----------------------------------------------------------------------------
# REGLA DE ORO / GOLDEN RULE
#
#   ES: NUNCA lances un --resync que haga ganar a ciegas a un lado
#       (--resync-mode path1 / path2). Si ese lado está desactualizado, pisará
#       en silencio el trabajo reciente del otro: es la forma más fácil de
#       perder datos con bisync. Si de verdad necesitas rebaseline, usa SIEMPRE
#       --resync --resync-mode newer, en una ventana tranquila y sin procesos
#       escribiendo en las carpetas.
#       Y sobre todo: ningún automatismo debe lanzar --resync por su cuenta. Un
#       "auto-reparador" que resincroniza a ciegas convierte una avería menor
#       (un listado corrupto) en pérdida de datos.
#
#   EN: NEVER run a --resync that blindly lets one side win
#       (--resync-mode path1 / path2). If that side is stale it will silently
#       overwrite the other side's recent work: it is the easiest way to lose
#       data with bisync. If you really need to rebaseline, always use
#       --resync --resync-mode newer, in a quiet window with nothing writing to
#       the folders.
#       Above all: no automation should ever fire --resync on its own. A
#       "self-healer" that blindly resyncs turns a minor breakage (a corrupt
#       listing) into data loss.
# -----------------------------------------------------------------------------
#
# Requisitos / Requirements:
#   - rclone instalado y configurado con un remote llamado 'gdrive'
#   - rclone installed and configured with a remote named 'gdrive'
#
# Logs: /tmp/rclone-bisync.log
# Backups: ~/.gdrive-bisync-backups  (ver --backup-dir2 / see --backup-dir2)
# =============================================================================
set -u

RCLONE=/opt/homebrew/bin/rclone   # Ajusta si rclone está en otra ruta
                                   # Adjust if rclone is in a different path

# Carpeta de iCloud a sincronizar / iCloud folder to sync
ICLOUD="/Users/$(whoami)/Library/Mobile Documents/com~apple~CloudDocs/Documents"

# Red de seguridad: copia de todo lo que se sobrescriba o borre en el lado local.
# DEBE estar FUERA de $ICLOUD, o se sincronizaría en bucle.
# Safety net: a copy of anything overwritten or deleted on the local side.
# It MUST live OUTSIDE $ICLOUD, otherwise it would sync in a loop.
BACKUP_LOCAL="/Users/$(whoami)/.gdrive-bisync-backups"
mkdir -p "$BACKUP_LOCAL"
# Poda a 30 días / Prune after 30 days
/usr/bin/find "$BACKUP_LOCAL" -type f -mtime +30 -delete 2>/dev/null
/usr/bin/find "$BACKUP_LOCAL" -type d -empty -delete 2>/dev/null

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
#     iCloud, se borra en Drive en la próxima ejecución (y viceversa). Ahora
#     bien: con --backup-dir2 el lado local guarda copia antes de borrar o
#     sobrescribir, así que un borrado propagado por error es recuperable.
#   - Deletions are AUTHORITATIVE on both sides. If you delete a file in
#     iCloud, it gets deleted in Drive on the next run (and vice versa).
#     That said: with --backup-dir2 the local side keeps a copy before deleting
#     or overwriting, so a wrongly propagated deletion is recoverable.
#
# Salvaguardas anti-desastre / Anti-disaster safeguards:
#
#   --check-access
#     ES: busca un canario `RCLONE_TEST` en cada lado. Si no aparece (señal de
#         que ese lado está vacío por error, no por intención), bisync ABORTA
#         sin tocar nada. Crear el marker UNA VEZ con:
#           touch "$ICLOUD/RCLONE_TEST" && rclone touch gdrive:RCLONE_TEST
#     EN: looks for an `RCLONE_TEST` canary on each side. If missing (a sign
#         that side is empty by error, not intent), bisync ABORTS without
#         touching anything. Create the marker ONCE with the command above.
#
#   --backup-dir2 "$BACKUP_LOCAL"
#     ES: nada del lado local se destruye en el sitio; se mueve antes a
#         $BACKUP_LOCAL. El lado Drive no lo necesita: Google Drive ya guarda
#         historial de versiones nativo (30 días), que es la red de seguridad
#         de ese lado.
#     EN: nothing on the local side is destroyed in place; it is moved to
#         $BACKUP_LOCAL first. The Drive side does not need this: Google Drive
#         already keeps native version history (30 days) as its safety net.
#
#   --max-delete 100
#     ES: cortafuegos. Si una pasada intentara borrar más de 100 ficheros,
#         ABORTA para que lo revises. Si el borrado masivo es intencionado,
#         pásale --max-delete N a mano.
#     EN: circuit breaker. If a run would delete more than 100 files it ABORTS
#         for review. If the mass deletion is intentional, pass --max-delete N.
#
#   --max-lock 15m
#     ES: los locks huérfanos que deja un run interrumpido expiran solos, en vez
#         de dejar el sync colgado indefinidamente hasta borrarlos a mano.
#     EN: stale locks left by an interrupted run expire on their own, instead of
#         hanging the sync indefinitely until removed by hand.
#
#   --recover
#     ES: se recupera de interrupciones sin exigir un --resync completo. Junto a
#         --max-lock, rompe el ciclo "run interrumpido -> must resync -> deriva".
#     EN: recovers from interruptions without demanding a full --resync. With
#         --max-lock, it breaks the "interrupted run -> must resync -> drift" loop.
#
#   --conflict-resolve newer + --conflict-loser num
#     ES: en un conflicto gana el más nuevo, y el perdedor se CONSERVA renombrado
#         (sufijo `conflict`). Nunca se pierde una versión en silencio.
#     EN: on a conflict the newer file wins and the loser is KEPT with a renamed
#         suffix (`conflict`). A version is never silently lost.
#
#   --drive-skip-gdocs
#     ES: imprescindible. Los documentos nativos de Google (Docs/Sheets/Slides)
#         no se pueden descargar tal cual y abortan la pasada con
#         "can't update google document type".
#     EN: essential. Native Google documents (Docs/Sheets/Slides) cannot be
#         downloaded as-is and will abort the run with
#         "can't update google document type".
"$RCLONE" bisync gdrive: "$ICLOUD" \
  --drive-skip-shortcuts \
  --drive-skip-gdocs \
  --create-empty-src-dirs \
  --resilient \
  --recover \
  --max-lock 15m \
  --check-access \
  --max-delete 100 \
  --conflict-resolve newer \
  --conflict-loser num \
  --conflict-suffix "conflict" \
  --backup-dir2 "$BACKUP_LOCAL" \
  --log-file "$LOG" \
  --log-level INFO \
  --exclude "node_modules/**" \
  --exclude ".git/**" \
  --exclude ".DS_Store" \
  --exclude "__pycache__/**" \
  --exclude "*.pyc" \
  --exclude "*.egg-info/**" \
  --exclude "Projects/**" \
  --exclude "Codex/**" \
  --exclude "Claude/**" \
  --exclude "CLAUDE/**" \
  --exclude "Alta Cliente/**" \
  --exclude ".venv/**" \
  --exclude "venv/**" \
  --exclude "*.bak" \
  --exclude "*.bak.*" \
  --exclude "*.tmp" \
  --exclude "*.swp" \
  --exclude ".angular/**" \
  --exclude ".next/**" \
  --exclude ".nuxt/**" \
  --exclude ".svelte-kit/**" \
  --exclude ".cache/**" \
  --exclude ".parcel-cache/**" \
  --exclude ".turbo/**" \
  --exclude "dist/**" \
  --exclude "build/**" \
  --exclude ".build/**" \
  --exclude ".swiftpm/**" \
  --exclude "DerivedData/**" \
  --exclude "*.xcuserdatad/**" \
  --exclude "*.xcuserstate" \
  --exclude "target/**" \
  --exclude "out/**" \
  --exclude "coverage/**" \
  --exclude ".nyc_output/**" \
  --exclude ".pytest_cache/**" \
  --exclude ".mypy_cache/**" \
  --exclude ".ruff_cache/**" \
  --exclude ".tox/**" \
  --exclude ".terraform/**" \
  --exclude "*.log" \
  --exclude "*.iso" \
  --exclude "*.qcow2" \
  --exclude "*.vmdk" \
  "$@"
