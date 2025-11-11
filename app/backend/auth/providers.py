import json
import base64
import requests
from typing import Dict, Any, Optional, Tuple
from jose import jwt
from jose.utils import base64url_decode
from .exceptions import AuthError
from ..core.config import settings

# 공통 반환 형태: (oauth_id, email, name, picture)

def google_from_id_token(id_token: str) -> Tuple[str, Optional[str], Optional[str], Optional[str]]:
    # 구글의 id_token(JWT) 검증 (서명/iss/aud 검증은 google.oauth 사용 권장이나,
    # 여기서는 간단 검증: 헤더/페이로드 파싱 + aud 매칭 정도)
    try:
        payload = jwt.get_unverified_claims(id_token)
    except Exception as e:
        raise AuthError("INVALID_GOOGLE_ID_TOKEN")

    if settings.GOOGLE_CLIENT_ID and payload.get("aud") != settings.GOOGLE_CLIENT_ID:
        raise AuthError("GOOGLE_AUDIENCE_MISMATCH")

    sub = payload.get("sub")
    if not sub:
        raise AuthError("GOOGLE_NO_SUB")
    return sub, payload.get("email"), payload.get("name"), payload.get("picture")

def apple_from_id_token(id_token: str) -> Tuple[str, Optional[str], Optional[str], Optional[str]]:
    # 단순 파싱 (실서비스: 애플의 JWKS로 서명 검증 필요)
    try:
        payload = jwt.get_unverified_claims(id_token)
    except Exception:
        raise AuthError("INVALID_APPLE_ID_TOKEN")
    # aud 검증 (선택)
    if settings.APPLE_CLIENT_ID and payload.get("aud") != settings.APPLE_CLIENT_ID:
        raise AuthError("APPLE_AUDIENCE_MISMATCH")
    sub = payload.get("sub")
    if not sub:
        raise AuthError("APPLE_NO_SUB")
    # 애플은 이메일이 비공개일 수 있음
    return sub, payload.get("email"), payload.get("name"), None

def kakao_from_access_token(access_token: str) -> Tuple[str, Optional[str], Optional[str], Optional[str]]:
    # Kakao v2 user API
    resp = requests.get(
        "https://kapi.kakao.com/v2/user/me",
        headers={"Authorization": f"Bearer {access_token}"},
        timeout=5,
    )
    if resp.status_code != 200:
        raise AuthError("KAKAO_TOKEN_INVALID")
    data = resp.json()
    kakao_id = str(data.get("id"))
    if not kakao_id:
        raise AuthError("KAKAO_NO_ID")
    kakao_account = data.get("kakao_account", {})
    profile = kakao_account.get("profile", {})
    email = kakao_account.get("email")
    name = profile.get("nickname")
    picture = profile.get("profile_image_url")
    return kakao_id, email, name, picture

def naver_from_access_token(access_token: str) -> Tuple[str, Optional[str], Optional[str], Optional[str]]:
    resp = requests.get(
        "https://openapi.naver.com/v1/nid/me",
        headers={"Authorization": f"Bearer {access_token}"},
        timeout=5,
    )
    if resp.status_code != 200:
        raise AuthError("NAVER_TOKEN_INVALID")
    data = resp.json().get("response", {})
    nid = data.get("id")
    if not nid:
        raise AuthError("NAVER_NO_ID")
    email = data.get("email")
    name = data.get("name") or data.get("nickname")
    picture = data.get("profile_image")
    return nid, email, name, picture
