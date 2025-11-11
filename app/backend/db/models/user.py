from pydantic import BaseModel, Field, EmailStr
from typing import Optional, Literal
from datetime import datetime

Provider = Literal["google", "apple", "kakao", "naver"]

class User(BaseModel):
    id: str = Field(alias="_id")
    provider: Provider
    oauth_id: str                # 구글 sub, 카카오 id, 네이버 id, 애플 sub
    email: Optional[EmailStr] = None
    name: Optional[str] = None
    picture: Optional[str] = None
    role: str = "tutor"
    created_at: datetime
    last_login_at: datetime
