"""
google_auth.py — Autorización OAuth2 para servicios Google
           OAuth2 authorization for Google services

Uso / Usage:
    python3 google_auth.py

Requisitos / Requirements:
    pip install google-auth-oauthlib google-api-python-client

Antes de ejecutar / Before running:
    1. Descarga tu client_secret.json desde Google Cloud Console
       Download your client_secret.json from Google Cloud Console
    2. Colócalo en el mismo directorio con el nombre: google_client_secret.json
       Place it in the same directory named: google_client_secret.json

Resultado / Output:
    Genera google_token.json con los tokens de acceso
    Generates google_token.json with access tokens
    ⚠️ Este archivo NO debe subirse a Git / This file must NOT be committed to Git
"""

import os
from pathlib import Path
from google_auth_oauthlib.flow import InstalledAppFlow
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
import json

# Directorio base del script
BASE_DIR = Path(__file__).parent

CLIENT_SECRET_FILE = BASE_DIR / "google_client_secret.json"
TOKEN_FILE = BASE_DIR / "google_token.json"

# Scopes solicitados — elimina los que no necesites
# Requested scopes — remove any you don't need
SCOPES = [
    "https://www.googleapis.com/auth/gmail.modify",
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/drive",
    "https://www.googleapis.com/auth/calendar",
    "https://www.googleapis.com/auth/youtube.readonly",
    "https://www.googleapis.com/auth/yt-analytics.readonly",
    "https://www.googleapis.com/auth/webmasters.readonly",
]


def get_credentials() -> Credentials:
    """Obtiene o refresca las credenciales OAuth2."""
    creds = None

    # Carga token existente si hay / Load existing token if any
    if TOKEN_FILE.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)

    # Si no hay token válido, solicita autorización / If no valid token, request authorization
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print("Refrescando token... / Refreshing token...")
            creds.refresh(Request())
        else:
            if not CLIENT_SECRET_FILE.exists():
                raise FileNotFoundError(
                    f"No se encontró {CLIENT_SECRET_FILE}\n"
                    f"Descárgalo de Google Cloud Console y guárdalo como:\n"
                    f"{CLIENT_SECRET_FILE}\n\n"
                    f"Could not find {CLIENT_SECRET_FILE}\n"
                    f"Download it from Google Cloud Console and save it as:\n"
                    f"{CLIENT_SECRET_FILE}"
                )
            flow = InstalledAppFlow.from_client_secrets_file(
                str(CLIENT_SECRET_FILE), SCOPES
            )
            print("\nAbriendo navegador para autorización...")
            print("Opening browser for authorization...\n")
            creds = flow.run_local_server(port=0)

        # Guarda el token / Save the token
        with open(TOKEN_FILE, "w") as f:
            f.write(creds.to_json())
        print(f"\n✅ Token guardado en / Token saved to: {TOKEN_FILE}")
        print("⚠️  NO subas este archivo a Git / Do NOT commit this file to Git")

    return creds


if __name__ == "__main__":
    creds = get_credentials()
    print(f"\n✅ Autorización completada / Authorization complete")
    print(f"   Account: {json.loads(TOKEN_FILE.read_text()).get('account', 'unknown')}")
    print(f"   Scopes: {len(SCOPES)} configurados / configured")
