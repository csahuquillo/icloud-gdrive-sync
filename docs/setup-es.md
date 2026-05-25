# Guía de instalación (Español)

## Parte 1 — Sincronización iCloud ↔ Google Drive

### Paso 1: Instalar rclone

```bash
brew install rclone
```

Verifica la instalación:
```bash
rclone version
```

### Paso 2: Crear un proyecto en Google Cloud y obtener credenciales OAuth

1. Ve a [console.cloud.google.com](https://console.cloud.google.com)
2. Crea un proyecto nuevo (ej. `mi-gdrive-sync`)
3. Activa la **Google Drive API**: APIs & Services → Enable APIs → busca "Google Drive API"
4. Crea credenciales OAuth 2.0:
   - APIs & Services → Credentials → Create Credentials → OAuth client ID
   - Application type: **Desktop app**
   - Descarga el JSON — guárdalo como `client_secret.json` (¡nunca lo subas a Git!)
5. En OAuth consent screen, añade tu email como "Test user" si la app está en modo Testing

### Paso 3: Configurar rclone con Google Drive

```bash
rclone config
```

Sigue estos pasos en el asistente interactivo:
- `n` → nuevo remote
- Nombre: `gdrive`
- Storage type: `drive` (Google Drive)
- Pega tu `client_id` y `client_secret` del JSON descargado
- Scope: `drive` (acceso completo)
- Deja en blanco: root_folder_id, service_account_file
- Auto config: `y` (se abrirá el navegador para autorizarte)
- Team drive: `n`

Verifica que funciona:
```bash
rclone lsd gdrive:
```

### Paso 4: Copiar el script de sincronización

```bash
mkdir -p ~/bin
cp scripts/gdrive-bisync.sh ~/bin/gdrive-bisync.sh
chmod +x ~/bin/gdrive-bisync.sh
```

Edita el script y ajusta la variable `ICLOUD` a tu ruta real:
```bash
nano ~/bin/gdrive-bisync.sh
```

Por defecto apunta a `~/Library/Mobile Documents/com~apple~CloudDocs/Documents`.  
Si quieres sincronizar otra carpeta de iCloud, cámbiala.

### Paso 5: Primera sincronización (resync)

La primera vez hay que hacer un `--resync` para que rclone establezca el estado inicial.  
**Google Drive manda** — si hay conflictos, prevalece Google Drive.

```bash
~/bin/gdrive-bisync.sh --resync
```

Esto puede tardar varios minutos dependiendo del volumen de archivos.  
Monitoriza el progreso:
```bash
tail -f /tmp/rclone-bisync.log
```

### Paso 6: Instalar el LaunchAgent (sync automático cada 5 minutos)

```bash
# Copia la plantilla
cp launchagents/com.usuario.gdrive-bisync.plist ~/Library/LaunchAgents/

# Edita y sustituye USERNAME por tu usuario de macOS
nano ~/Library/LaunchAgents/com.usuario.gdrive-bisync.plist

# Renómbralo con tu nombre de usuario (opcional, mejor práctica)
mv ~/Library/LaunchAgents/com.usuario.gdrive-bisync.plist \
   ~/Library/LaunchAgents/com.$(whoami).gdrive-bisync.plist

# Cárgalo
launchctl load ~/Library/LaunchAgents/com.$(whoami).gdrive-bisync.plist
```

Verifica que está activo:
```bash
launchctl list | grep gdrive
```

A partir de ahora se ejecutará automáticamente cada 5 minutos.

---

## Parte 2 — Skill de Google para Claude (Agent Hub)

### Requisitos previos

```bash
pip3 install google-auth-oauthlib google-api-python-client
```

### Paso 1: Preparar el directorio del agent hub

```bash
mkdir -p ~/Documents/Projects/agent-hub
cp agent-hub/google_auth.py ~/Documents/Projects/agent-hub/
cp agent-hub/.env.local.example ~/Documents/Projects/agent-hub/.env.local
```

### Paso 2: Configurar las credenciales

Copia tu `client_secret.json` (el mismo del paso anterior) al directorio:
```bash
cp client_secret.json ~/Documents/Projects/agent-hub/google_client_secret.json
```

> ⚠️ Este archivo NUNCA debe subirse a Git. Está incluido en el `.gitignore`.

### Paso 3: Autorizar la aplicación

```bash
cd ~/Documents/Projects/agent-hub
python3 google_auth.py
```

Se abrirá el navegador para que autorices el acceso. Después se generará  
`google_token.json` — también excluido del Git.

Los scopes que se solicitan son:
- `gmail.modify` + `gmail.send` — leer y enviar correos
- `drive` — acceso completo a Google Drive
- `calendar` — leer y escribir eventos
- `youtube.readonly` + `yt-analytics.readonly` — estadísticas de YouTube
- `webmasters.readonly` — Search Console

Puedes eliminar los scopes que no necesites editando `google_auth.py`.

### Paso 4: Instalar el skill en Claude

Copia la carpeta del skill a tu directorio de plugins de Claude:
```bash
# Para Claude Code
cp -r agent-hub/skills/google ~/.claude/skills/

# Para Cowork (ajusta la ruta a tu instalación)
# La ruta varía según la versión; consulta la documentación de Cowork
```

Una vez instalado, en Claude puedes invocar el skill con `/google` o simplemente  
describir lo que necesitas: *"busca en mi Drive los documentos de contabilidad de 2025"*.

---

## Estructura de archivos resultante

```
~/
├── bin/
│   └── gdrive-bisync.sh          # Script de sincronización
├── Library/
│   └── LaunchAgents/
│       └── com.TU_USUARIO.gdrive-bisync.plist
└── Documents/
    └── Projects/
        └── agent-hub/
            ├── google_auth.py
            ├── google_token.json      # ← generado, NO en Git
            └── google_client_secret.json  # ← descargado, NO en Git
```
