# Seguridad / Security

## 🇪🇸 Qué NO debe subirse jamás a Git

Estos archivos contienen credenciales reales y **nunca deben aparecer en el repositorio**:

| Archivo | Contiene | Por qué es peligroso |
|---|---|---|
| `google_token.json` | Token OAuth activo con refresh token | Permite acceso completo a tu Google sin contraseña |
| `google_client_secret.json` | Client ID + Client Secret de Google Cloud | Permite crear tokens en tu nombre |
| `.env.local` | Claves de API de otros servicios | Acceso a todos los servicios configurados |
| `rclone.conf` | Tokens de acceso a Google Drive | Acceso completo a tu Drive |
| `*.pem`, `*.key`, `*.p12` | Claves privadas | Acceso criptográfico a servicios |

Todos están incluidos en el `.gitignore` de este repositorio.

### Antes de hacer cualquier commit:

```bash
# Revisa que ningún secreto está siendo incluido
git diff --cached

# O usa git-secrets para protección automática
brew install git-secrets
git secrets --install
git secrets --register-aws  # detecta patrones tipo token
```

### Si accidentalmente subes un secreto:

1. **Revoca inmediatamente** el token/credencial comprometida en Google Cloud Console
2. Genera uno nuevo
3. Limpia el historial de Git:
   ```bash
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch ARCHIVO_COMPROMETIDO' \
     --prune-empty --tag-name-filter cat -- --all
   git push origin --force --all
   ```
   O usa [BFG Repo Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) que es más sencillo.

---

## 🇬🇧 What must NEVER be committed to Git

These files contain real credentials and **must never appear in the repository**:

| File | Contains | Why it's dangerous |
|---|---|---|
| `google_token.json` | Active OAuth token with refresh token | Grants full Google access without a password |
| `google_client_secret.json` | Google Cloud Client ID + Secret | Allows creating tokens on your behalf |
| `.env.local` | API keys for other services | Access to all configured services |
| `rclone.conf` | Google Drive access tokens | Full Drive access |
| `*.pem`, `*.key`, `*.p12` | Private keys | Cryptographic access to services |

All of these are included in this repository's `.gitignore`.

### Before making any commit:

```bash
# Check that no secrets are being staged
git diff --cached

# Or use git-secrets for automatic protection
brew install git-secrets
git secrets --install
git secrets --register-aws  # detects token-like patterns
```

### If you accidentally push a secret:

1. **Immediately revoke** the compromised token/credential in Google Cloud Console
2. Generate a new one
3. Clean the Git history:
   ```bash
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch COMPROMISED_FILE' \
     --prune-empty --tag-name-filter cat -- --all
   git push origin --force --all
   ```
   Or use [BFG Repo Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) for an easier approach.
