# app/backend/main.py
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse, JSONResponse
from google_auth_oauthlib.flow import Flow
import logging
import os
from pathlib import Path
from api.v1.endpoints import router as v1_router

# ─────────────────────────────────────────────────────────────
# ⚙️ Settings
# ─────────────────────────────────────────────────────────────
# DEV ONLY: 로컬에서 http 콜백 허용 (배포 시 제거!)
os.environ.setdefault("OAUTHLIB_INSECURE_TRANSPORT", "1")

CLIENT_SECRET_FILE = os.getenv("GOOGLE_CLIENT_SECRET_FILE", "credentials.json")
SCOPES = ["https://www.googleapis.com/auth/calendar"]
TOKEN_PATH = Path(os.getenv("GOOGLE_TOKEN_PATH", "token.json")).resolve()

# ─────────────────────────────────────────────────────────────
# 🚏 FastAPI
# ─────────────────────────────────────────────────────────────
app = FastAPI(title="Tutor AI Backend", version="0.0.1")


# CORS (필요할 때 허용 도메인 좁히기 권장)
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ALLOW_ORIGINS", "*").split(","),
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(v1_router, prefix="/api/v1")

# ─────────────────────────────────────────────────────────────
# 🏠 Health / Root
# ─────────────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"ok": True}

@app.get("/")
def root():
    return {"message": "TutorAI backend running 🚀"}


# ─────────────────────────────────────────────────────────────
# 🔐 Google Calendar OAuth
# ─────────────────────────────────────────────────────────────
# def _build_redirect_uri(request: Request) -> str:
#     """
#     배포/프록시/포트 상황에 맞춰 콜백 URL을 안전하게 생성.
#     - 배포 시 https가 강제될 수도 있으니 X-Forwarded-Proto 반영됨(ProxyHeadersMiddleware).
#     """
#     return str(request.url_for("google_auth_callback"))

# def _new_flow(redirect_uri: str) -> Flow:
#     if not Path(CLIENT_SECRET_FILE).exists():
#         raise FileNotFoundError(
#             f"[OAuth] credentials.json을 찾을 수 없습니다: {Path(CLIENT_SECRET_FILE).resolve()}"
#         )
#     return Flow.from_client_secrets_file(
#         CLIENT_SECRET_FILE,
#         scopes=SCOPES,
#         redirect_uri=redirect_uri,
#     )

# @app.get("/auth")
# def google_auth(request: Request):
#     try:
#         redirect_uri = _build_redirect_uri(request)
#         flow = _new_flow(redirect_uri)
#         # refresh token 받으려면 access_type=offline 필요
#         auth_url, state = flow.authorization_url(
#             prompt="consent",
#             access_type="offline",
#             include_granted_scopes="true",
#         )
#         logging.info(f"[Google OAuth] Redirecting to: {auth_url}")
#         return RedirectResponse(auth_url)
#     except Exception as e:
#         logging.exception("[Google OAuth] auth init failed")
#         raise HTTPException(status_code=500, detail=str(e))

# @app.get("/auth/callback", name="google_auth_callback")
# def google_auth_callback(request: Request):
#     try:
#         redirect_uri = _build_redirect_uri(request)
#         flow = _new_flow(redirect_uri)

#         # request.url 에 code/state 포함되어 옴
#         flow.fetch_token(authorization_response=str(request.url))
#         creds = flow.credentials

#         # token.json 저장 (Windows도 OK)
#         TOKEN_PATH.write_text(creds.to_json(), encoding="utf-8")
#         logging.info(f"✅ Google Calendar OAuth 저장됨 → {TOKEN_PATH}")

#         # 필요하다면 FE로 리다이렉트
#         frontend_url = os.getenv("OAUTH_SUCCESS_REDIRECT", "/")
#         return RedirectResponse(frontend_url)

#     except Exception as e:
#         logging.exception("[Google OAuth] callback failed")
#         # 디버깅 편하게 상세 메시지 반환(운영에선 축소 권장)
#         return JSONResponse(
#             status_code=500,
#             content={"message": "OAuth callback error", "error": str(e)},
#         )
