---
name: google
description: >
  Connects to Google services (Gmail, Drive, Calendar, YouTube, Search Console)
  using OAuth2. Read emails, search documents, manage calendar events, YouTube
  analytics, Search Console SEO data. Credentials at
  ~/Documents/Projects/agent-hub/google_token.json.
---

# Skill: /google

Always read before acting:
- `~/Documents/Projects/agent-hub/google_token.json` — OAuth token with refresh

Configure your account in `~/Documents/Projects/agent-hub/.env.local`.

---

## Setup on a new machine

```bash
cd ~/Documents/Projects/agent-hub
pip3 install google-auth-oauthlib google-api-python-client
python3 google_auth.py   # opens browser for authorization on first run
```

Requires `google_client_secret.json` (from Google Cloud Console).

---

## Active scopes

| Scope | Service | Permissions |
|---|---|---|
| `gmail.modify` | Gmail | Read, label, archive, delete (not send) |
| `gmail.send` | Gmail | Send emails |
| `drive` | Drive | Full read + write |
| `calendar` | Calendar | Full read + write |
| `youtube.readonly` | YouTube | Read only (videos, comments) |
| `yt-analytics.readonly` | YouTube Analytics | Channel statistics |
| `webmasters.readonly` | Search Console | SEO, performance, indexing |

---

## Python helper — common client

```python
from pathlib import Path
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials

TOKEN = Path.home() / "Documents/Projects/agent-hub/google_token.json"

def google_service(api: str, version: str):
    """api: 'gmail'|'drive'|'calendar'|'youtube'|'youtubeAnalytics'|'searchconsole'"""
    creds = Credentials.from_authorized_user_file(str(TOKEN))
    return build(api, version, credentials=creds, cache_discovery=False)
```

---

## Gmail

```python
service = google_service("gmail", "v1")

# List unread emails
results = service.users().messages().list(
    userId="me", q="is:unread", maxResults=20
).execute()

# Get a message
msg = service.users().messages().get(
    userId="me", id=MESSAGE_ID, format="full"
).execute()

# Send an email
import base64
from email.mime.text import MIMEText

message = MIMEText("Body text")
message["to"] = "recipient@example.com"
message["subject"] = "Subject"
raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
service.users().messages().send(userId="me", body={"raw": raw}).execute()
```

---

## Google Drive

```python
service = google_service("drive", "v3")

# Search files
results = service.files().list(
    q="name contains 'report' and mimeType != 'application/vnd.google-apps.folder'",
    fields="files(id, name, mimeType, modifiedTime, size)",
    pageSize=20
).execute()

# Download file content
import io
request = service.files().get_media(fileId=FILE_ID)
content = io.BytesIO()
from googleapiclient.http import MediaIoBaseDownload
downloader = MediaIoBaseDownload(content, request)
done = False
while not done:
    _, done = downloader.next_chunk()

# Upload a file
from googleapiclient.http import MediaFileUpload
media = MediaFileUpload("local_file.pdf", mimetype="application/pdf")
service.files().create(
    body={"name": "uploaded_file.pdf", "parents": [FOLDER_ID]},
    media_body=media
).execute()
```

---

## Google Calendar

```python
service = google_service("calendar", "v3")

# List upcoming events
from datetime import datetime, timezone
events = service.events().list(
    calendarId="primary",
    timeMin=datetime.now(timezone.utc).isoformat(),
    maxResults=10,
    singleEvents=True,
    orderBy="startTime"
).execute()

# Create an event
event = {
    "summary": "Meeting",
    "start": {"dateTime": "2025-06-01T10:00:00", "timeZone": "Europe/Madrid"},
    "end":   {"dateTime": "2025-06-01T11:00:00", "timeZone": "Europe/Madrid"},
}
service.events().insert(calendarId="primary", body=event).execute()
```

---

## YouTube Analytics

```python
service = google_service("youtubeAnalytics", "v2")

report = service.reports().query(
    ids="channel==MINE",
    startDate="2025-01-01",
    endDate="2025-12-31",
    metrics="views,estimatedMinutesWatched,subscribers",
    dimensions="day"
).execute()
```

---

## Search Console

```python
service = google_service("searchconsole", "v1")

# List properties
sites = service.sites().list().execute()

# Query performance data
response = service.searchanalytics().query(
    siteUrl="https://yoursite.com",
    body={
        "startDate": "2025-01-01",
        "endDate": "2025-12-31",
        "dimensions": ["query"],
        "rowLimit": 25
    }
).execute()
```
