# Installation Guide (English)

## Part 1 — iCloud ↔ Google Drive Sync

### Step 1: Install rclone

```bash
brew install rclone
```

Verify the installation:
```bash
rclone version
```

### Step 2: Create a Google Cloud project and obtain OAuth credentials

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project (e.g. `my-gdrive-sync`)
3. Enable the **Google Drive API**: APIs & Services → Enable APIs → search "Google Drive API"
4. Create OAuth 2.0 credentials:
   - APIs & Services → Credentials → Create Credentials → OAuth client ID
   - Application type: **Desktop app**
   - Download the JSON — save it as `client_secret.json` (never commit this to Git!)
5. On the OAuth consent screen, add your email as a "Test user" if the app is in Testing mode

### Step 3: Configure rclone with Google Drive

```bash
rclone config
```

Follow these steps in the interactive wizard:
- `n` → new remote
- Name: `gdrive`
- Storage type: `drive` (Google Drive)
- Paste your `client_id` and `client_secret` from the downloaded JSON
- Scope: `drive` (full access)
- Leave blank: root_folder_id, service_account_file
- Auto config: `y` (your browser will open for authorization)
- Team drive: `n`

Verify it works:
```bash
rclone lsd gdrive:
```

### Step 4: Copy the sync script

```bash
mkdir -p ~/bin
cp scripts/gdrive-bisync.sh ~/bin/gdrive-bisync.sh
chmod +x ~/bin/gdrive-bisync.sh
```

Edit the script and adjust the `ICLOUD` variable to your actual path:
```bash
nano ~/bin/gdrive-bisync.sh
```

By default it points to `~/Library/Mobile Documents/com~apple~CloudDocs/Documents`.  
Change it if you want to sync a different iCloud folder.

### Step 5: First sync (resync)

The first time, you must run `--resync` so rclone can establish the initial state.  
**Google Drive wins** — if there are conflicts, Google Drive takes precedence.

```bash
~/bin/gdrive-bisync.sh --resync
```

This may take several minutes depending on how many files you have.  
Monitor progress:
```bash
tail -f /tmp/rclone-bisync.log
```

### Step 6: Install the LaunchAgent (automatic sync every 5 minutes)

```bash
# Copy the template
cp launchagents/com.usuario.gdrive-bisync.plist ~/Library/LaunchAgents/

# Edit and replace USERNAME with your macOS username
nano ~/Library/LaunchAgents/com.usuario.gdrive-bisync.plist

# Rename it with your username (optional, best practice)
mv ~/Library/LaunchAgents/com.usuario.gdrive-bisync.plist \
   ~/Library/LaunchAgents/com.$(whoami).gdrive-bisync.plist

# Load it
launchctl load ~/Library/LaunchAgents/com.$(whoami).gdrive-bisync.plist
```

Verify it is active:
```bash
launchctl list | grep gdrive
```

From now on it will run automatically every 5 minutes.

---

## Part 2 — Google Skill for Claude (Agent Hub)

### Prerequisites

```bash
pip3 install google-auth-oauthlib google-api-python-client
```

### Step 1: Prepare the agent hub directory

```bash
mkdir -p ~/Documents/Projects/agent-hub
cp agent-hub/google_auth.py ~/Documents/Projects/agent-hub/
cp agent-hub/.env.local.example ~/Documents/Projects/agent-hub/.env.local
```

### Step 2: Configure credentials

Copy your `client_secret.json` (the same one from earlier) to the directory:
```bash
cp client_secret.json ~/Documents/Projects/agent-hub/google_client_secret.json
```

> ⚠️ This file must NEVER be committed to Git. It is included in `.gitignore`.

### Step 3: Authorize the application

```bash
cd ~/Documents/Projects/agent-hub
python3 google_auth.py
```

Your browser will open so you can authorize access. Afterwards,  
`google_token.json` will be generated — also excluded from Git.

The scopes requested are:
- `gmail.modify` + `gmail.send` — read and send emails
- `drive` — full Google Drive access
- `calendar` — read and write events
- `youtube.readonly` + `yt-analytics.readonly` — YouTube analytics
- `webmasters.readonly` — Search Console

You can remove any scopes you don't need by editing `google_auth.py`.

### Step 4: Install the skill in Claude

Copy the skill folder to your Claude plugins directory:
```bash
# For Claude Code
cp -r agent-hub/skills/google ~/.claude/skills/

# For Cowork (adjust the path to your installation)
# The path varies by version; refer to the Cowork documentation
```

Once installed, you can invoke the skill in Claude with `/google` or simply  
describe what you need: *"search my Drive for the accounting documents from 2025"*.

---

## Resulting file structure

```
~/
├── bin/
│   └── gdrive-bisync.sh          # Sync script
├── Library/
│   └── LaunchAgents/
│       └── com.YOUR_USERNAME.gdrive-bisync.plist
└── Documents/
    └── Projects/
        └── agent-hub/
            ├── google_auth.py
            ├── google_token.json          # ← generated, NOT in Git
            └── google_client_secret.json  # ← downloaded, NOT in Git
```
