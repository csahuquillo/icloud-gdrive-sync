# iCloud ↔ Google Drive Sync

> **Sincronización bidireccional automática entre iCloud Drive y Google Drive.**
>
> **Automatic bidirectional sync between iCloud Drive and Google Drive.**

---

## 🇪🇸 Español

### ¿Qué es esto?

Mantiene tu carpeta `Documents` de iCloud en espejo exacto con Google Drive usando `rclone bisync`. Pensado para trabajar desde Mac con iCloud y desde Windows/Linux con Google Drive, sin perder nada.

El script comprueba antes de arrancar que las APIs de Google son accesibles. Si
el Mac está sin conexión, en una red cautiva, en un tren o en un avión, registra
un aviso y no lanza `rclone bisync`, evitando errores críticos por falta de red.

### ¿Para quién es útil?

- Usuarios de Mac con iCloud que también necesitan acceder a sus archivos desde Windows (donde iCloud no está disponible o está filtrado en el trabajo)
- Quienes quieran un backup automático de iCloud en Google Drive
- Cualquiera que trabaje en múltiples sistemas operativos y quiera que sus archivos estén siempre disponibles

### Arquitectura

```
[iCloud Documents] ←──rclone bisync──→ [Google Drive]
         ↑                                    ↑
   LaunchAgent                         gdrive remote
 (cada hora, L–V)                   (OAuth2 configurado)
```

---

## 🇬🇧 English

### What is this?

Keeps your iCloud `Documents` folder as an exact mirror of Google Drive using `rclone bisync`. Designed to let you work from Mac via iCloud and from Windows/Linux via Google Drive without losing anything.

Before starting, the script checks that Google APIs are reachable. If the Mac is
offline, behind a captive network, on a train, or on a plane, it logs a notice
and skips `rclone bisync`, avoiding critical sync errors caused by missing
network connectivity.

### Who is this for?

- Mac users with iCloud who also need to access files from Windows (where iCloud is unavailable or blocked at work)
- Anyone who wants an automatic iCloud backup to Google Drive
- Anyone working across multiple operating systems who wants their files always available

### Architecture

```
[iCloud Documents] ←──rclone bisync──→ [Google Drive]
         ↑                                    ↑
   LaunchAgent                         gdrive remote
 (hourly, Mon–Fri)                  (OAuth2 configured)
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
| Google Cloud Project | — | Para OAuth2 / For OAuth2 |

---

## Licencia / License

MIT — úsalo, modifícalo, compártelo. / Use it, modify it, share it.
