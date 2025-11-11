# app/backend/core/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field
from pathlib import Path

# core/config.py -> parents[1] == app/backend
ENV_FILE = Path(__file__).resolve().parents[1] / ".env"

class Settings(BaseSettings):
    DATABASE_URL: str = Field(..., description="SQLAlchemy async URL")
    AES_KEY_B64: str | None = None
    HMAC_KEY_B64: str | None = None
    ENV: str = "local"
    
    # 카카오페이 설정
    KAKAO_PAY_ADMIN_KEY: str | None = None  # 카카오페이 Admin Key
    KAKAO_PAY_CID: str = "TC0ONETIME"  # 테스트용 CID (실서비스는 실제 CID 사용)
    KAKAO_PAY_TEST_MODE: bool = True  # 테스트 모드 (실제 API 호출 없이 모의 응답)
    
    # OpenAI 설정
    OPENAI_API_KEY: str | None = None  # OpenAI API Key
    OPENAI_MODEL: str = "gpt-4o"  # 사용할 모델

    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE),
        env_file_encoding="utf-8",
        extra="ignore",
    )

settings = Settings()
