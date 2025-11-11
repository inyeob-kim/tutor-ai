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

    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE),
        env_file_encoding="utf-8",
        extra="ignore",
    )

settings = Settings()
