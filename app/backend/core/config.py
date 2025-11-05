from pydantic_settings import BaseSettings
import pytz

class Settings(BaseSettings):
    OPENAI_API_KEY: str
    OPENAI_MODEL: str = "gpt-4o-mini"
    TIMEZONE: str = "Asia/Seoul"  

    class Config:
        env_file = ".env"
        extra = "ignore"   # Ignore any other unknown vars (optional)

settings = Settings()

# Create timezone object
LOCAL_TZ = pytz.timezone(settings.TIMEZONE)