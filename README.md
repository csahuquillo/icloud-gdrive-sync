# iCloud ↔ Google Drive Sync + Claude Agent Hub

> **Sincronización bidireccional automática entre iCloud Drive y Google Drive, con integración de servicios Google para Claude AI.**
>
> **Automatic bidirectional sync between iCloud Drive and Google Drive, with Google services integration for Claude AI.**

---

## 🇪🇸 Español

### ¿Qué es esto?

Un sistema en dos partes:

1. **Sync automático iCloud ↔ Google Drive** — mantiene tu carpeta `Documents` de iCloud en espejo exacto con Google Drive usando `rclone bisync`. Pensado para trabajar desde Mac con iCloud y desde Windows/Linux con Google Drive, sin perder nada.

2. **Agent Hub para Claude** — un skill de Claude (vía Cowork o Claude Code) que te permite interactuar con Gmail, Google Drive, Google Calendar, YouTube y Search Console usando lenguaje natural.

### ¿Para quién es útil?

- Usuarios de Mac con iCloud que también necesitan acceder a sus archivos desde Windows (donde iCloud no está disponible o está filtrado)
- Quienes usan Claude AI y quieren conectarlo a sus servicios Google
- Cualquiera que quiera un backup automático de iCloud en Google Drive

### Arquitectura

```
[iCloud Documents] ←──rclone bisync──→ [Google Drive]
         ↑                                    ↑
   LaunchAgent                         gdrive remote
 (cada 5 minutos)                   (OAuth2 configurado)
         
[Claude AI] ←── agent-hub/google skill ──→ [Gmail / Drive / Calendar / YouTube]
```

---

## 🇬🇧 English

### What is this?

A two-part system:

1. **Automatic iCloud ↔ Google Drive sync** — keeps your iCloud `Documents` folder as an exact mirror of Google Drive using `rclone bisync`. Designed to let you work from Mac via iCloud and from Windows/Linux via Google Drive without losing anything.

2. **Agent Hub for Claude** — a Claude skill (via Cowork or Claude Code) that lets you interact with Gmail, Google Drive, Google Calendar, YouTube, and Search Console using natural language.

### Who is this for?

- Mac users with iCloud who also need to access files from Windows (where iCloud is unavailable or blocked)
- People who use Claude AI and want to connect it to their Google services
- Anyone who wants an automatic iCloud backup to Google Drive

### Architecture

```
[iCloud Documents] ←──rclone bisync──→ [Google Drive]
         ↑                                    ↑
   LaunchAgent                         gdrive remote
 (every 5 minutes)                  (OAuth2 configured)
         
[Claude AI] ←── agent-hub/google skill ──→ [Gmail / Drive / Calendar / YouTube]
```

---

## Índice / Table of Contents

- [Requisitos / Requirements](#requisitos--requirements)
- [Instalación / Installation](docs/setup-es.md) · [English](docs/setup-en.md)
- [Seguridad / Security](SECURITY.md)
- [Solución de problemas / Troubleshooting](docs/troubleshooting.md)
- [Licencia / License](#licencia--license)

---

## Requisitos / Requirements

| Herramienta / Tool | Versión / Version | Notas / Notes |
|---|---|---|
| macOS | 12+ | iCloud Drive activado / enabled |
| [rclone](https://rclone.org) | 1.65+ | `brew install rclone` |
| Python | 3.9+ | Para el agent hub / For agent hub |
| Google Cloud Project | — | Para OAuth2 / For OAuth2 |
| Claude (Cowork o API) | — | Para el skill / For the skill |

---

## Licencia / License

MIT — úsalo, modifícalo, compártelo. / Use it, modify it, share it.
