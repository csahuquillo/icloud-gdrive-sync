# Solución de problemas / Troubleshooting

## 🇪🇸 Problemas frecuentes

### El bisync se queda bloqueado / no termina

**Síntoma:** El proceso lleva horas corriendo sin avanzar.

**Causa probable:** Hay una carpeta con miles de archivos que no está excluida (típicamente `venv/`, `node_modules/` o `.git/`).

**Solución:**
```bash
# Mata el proceso
pkill -f "rclone bisync"

# Borra los state files
rm -f ~/Library/Caches/rclone/bisync/*.lst*

# Añade el exclude al script y vuelve a ejecutar con --resync
~/bin/gdrive-bisync.sh --resync
```

---

### Error: "prior lock file found"

**Mensaje:**
```
Failed to bisync: prior lock file found: .../gdrive_...lck
```

**Causa:** Una ejecución anterior fue interrumpida y dejó un lock file.

**Solución:**
```bash
# Opción 1: borra el lock file manualmente
rm ~/Library/Caches/rclone/bisync/*.lck

# Opción 2: usa el comando que te indica rclone en el error
rclone deletefile "gdrive:.lck"

# Luego vuelve a ejecutar
~/bin/gdrive-bisync.sh
```

---

### Archivos duplicados en Google Drive

**Mensaje:**
```
NOTICE: archivo.pdf: Duplicate object found in destination - ignoring
```

**Causa:** Google Drive permite tener dos archivos con el mismo nombre en la misma carpeta (algo que iCloud no permite). rclone ignora el duplicado.

**Solución:** Entra a Google Drive en el navegador, localiza el duplicado y elimina el que no quieras conservar.

---

### El LaunchAgent no se ejecuta

**Comprobación:**
```bash
launchctl list | grep gdrive
```

Si no aparece, cárgalo:
```bash
launchctl load ~/Library/LaunchAgents/com.$(whoami).gdrive-bisync.plist
```

Si aparece pero con un código de error, comprueba los logs:
```bash
tail -50 /tmp/rclone-bisync.log
```

---

### rclone no encuentra el remote "gdrive"

**Mensaje:**
```
Failed to create file system for "gdrive:": didn't find section in config file
```

**Solución:**
```bash
rclone config  # y sigue los pasos para crear el remote 'gdrive'
rclone listremotes  # debe aparecer 'gdrive:'
```

---

### Token expirado / error de autenticación

**Mensaje:**
```
Failed to refresh token: oauth2: cannot fetch token
```

**Solución:**
```bash
# Re-autoriza rclone
rclone config reconnect gdrive:
```

O si usas el agent hub de Claude:
```bash
cd ~/Documents/Projects/agent-hub
python3 google_auth.py  # vuelve a autorizar en el navegador
```

---

## 🇬🇧 Common issues

### Bisync gets stuck / never finishes

**Symptom:** The process has been running for hours without progress.

**Likely cause:** There's a folder with thousands of files that isn't excluded (typically `venv/`, `node_modules/` or `.git/`).

**Solution:**
```bash
# Kill the process
pkill -f "rclone bisync"

# Delete the state files
rm -f ~/Library/Caches/rclone/bisync/*.lst*

# Add the exclude to the script and run again with --resync
~/bin/gdrive-bisync.sh --resync
```

---

### Error: "prior lock file found"

**Message:**
```
Failed to bisync: prior lock file found: .../gdrive_...lck
```

**Cause:** A previous run was interrupted and left a lock file behind.

**Solution:**
```bash
# Option 1: delete the lock file manually
rm ~/Library/Caches/rclone/bisync/*.lck

# Option 2: use the command rclone shows in the error message
rclone deletefile "gdrive:.lck"

# Then run again
~/bin/gdrive-bisync.sh
```

---

### Duplicate files in Google Drive

**Message:**
```
NOTICE: file.pdf: Duplicate object found in destination - ignoring
```

**Cause:** Google Drive allows two files with the same name in the same folder (something iCloud does not allow). rclone ignores the duplicate.

**Solution:** Open Google Drive in your browser, find the duplicate, and delete the one you don't want to keep.

---

### LaunchAgent doesn't run

**Check:**
```bash
launchctl list | grep gdrive
```

If it doesn't appear, load it:
```bash
launchctl load ~/Library/LaunchAgents/com.$(whoami).gdrive-bisync.plist
```

If it appears with an error code, check the logs:
```bash
tail -50 /tmp/rclone-bisync.log
```

---

### rclone can't find the "gdrive" remote

**Message:**
```
Failed to create file system for "gdrive:": didn't find section in config file
```

**Solution:**
```bash
rclone config  # follow the steps to create the 'gdrive' remote
rclone listremotes  # 'gdrive:' should appear
```

---

### Expired token / authentication error

**Message:**
```
Failed to refresh token: oauth2: cannot fetch token
```

**Solution:**
```bash
# Re-authorize rclone
rclone config reconnect gdrive:
```

Or if you use the Claude agent hub:
```bash
cd ~/Documents/Projects/agent-hub
python3 google_auth.py  # re-authorize in your browser
```
