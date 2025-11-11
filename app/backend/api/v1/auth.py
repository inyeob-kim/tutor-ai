from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Literal, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase

from ...db.database import get_db
from ...core.jwt import create_access_token
from ...services.user_service import upsert_social_user
from ...auth.providers import (
    google_from_id_token, apple_from_id_token,
    kakao_from_access_token, naver_from_access_token
)
from ...auth.exceptions import AuthError

router = APIRouter(prefix="/auth", tags=["auth"])

Provider = Literal["google", "apple", "kakao", "naver"]

class SocialLoginIn(BaseModel):
    provider: Provider = Field(..., description="google|apple|kakao|naver")
    id_token: Optional[str] = None
    access_token: Optional[str] = None

@router.post("/social-login")
async def social_login(payload: SocialLoginIn, db: AsyncIOMotorDatabase = Depends(get_db)):
    try:
        if payload.provider == "google":
            if not payload.id_token:
                raise HTTPException(400, "id_token required for google")
            sub, email, name, picture = google_from_id_token(payload.id_token)

        elif payload.provider == "apple":
            if not payload.id_token:
                raise HTTPException(400, "id_token required for apple")
            sub, email, name, picture = apple_from_id_token(payload.id_token)

        elif payload.provider == "kakao":
            if not payload.access_token:
                raise HTTPException(400, "access_token required for kakao")
            sub, email, name, picture = kakao_from_access_token(payload.access_token)

        elif payload.provider == "naver":
            if not payload.access_token:
                raise HTTPException(400, "access_token required for naver")
            sub, email, name, picture = naver_from_access_token(payload.access_token)

        else:
            raise HTTPException(400, "unsupported provider")

        user = await upsert_social_user(
            db,
            provider=payload.provider,
            oauth_id=sub,
            email=email,
            name=name,
            picture=picture,
        )
        jwt = create_access_token(user.id, extra={"provider": payload.provider})
        return {"access_token": jwt, "user": user.model_dump(by_alias=True)}

    except AuthError as e:
        raise HTTPException(status_code=401, detail=e.code)
