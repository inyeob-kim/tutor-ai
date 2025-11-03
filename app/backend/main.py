from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from google_auth_oauthlib.flow import Flow
import logging

# ✅ Router import (정확한 파일명)
from app.backend.routers.scheduling_controller import router as scheduling_router

app = FastAPI(title="Tutor AI Backend", version="0.0.1")

# ✅ CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Router 등록
app.include_router(scheduling_router)

@app.get("/")
def root():
    return {"message": "TutorAI backend running 🚀"}


# ✅ Google Calendar 인증
CLIENT_SECRET_FILE = "credentials.json"
SCOPES = ["https://www.googleapis.com/auth/calendar"]


@app.get("/auth")
def google_auth():
    flow = Flow.from_client_secrets_file(
        CLIENT_SECRET_FILE,
        scopes=SCOPES,
        redirect_uri="http://localhost:8000/auth/callback",
    )
    auth_url, _ = flow.authorization_url(prompt="consent")

    logging.info(f"[Google OAuth] Redirecting to: {auth_url}")
    return RedirectResponse(auth_url)


@app.get("/auth/callback")
def google_auth_callback(request: Request):
    flow = Flow.from_client_secrets_file(
        CLIENT_SECRET_FILE,
        scopes=SCOPES,
        redirect_uri="http://localhost:8000/auth/callback",
    )

    flow.fetch_token(authorization_response=str(request.url))
    creds = flow.credentials

    with open("token.json", "w") as token:
        token.write(creds.to_json())

    logging.info("✅ Google Calendar OAuth 저장됨 → token.json")

    return {"message": "✅ Google Calendar 연동 완료!"}
