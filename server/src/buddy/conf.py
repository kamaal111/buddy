import pytz
from pydantic_extra_types.timezone_name import TimeZoneName
from pydantic_settings import BaseSettings, SettingsConfigDict

DATABASE_USER = "buddy-user"
DATABASE_PASSWORD = "secure-password"
DATABASE_HOST = "db"
DATABASE_PORT = "5432"
DATABASE_NAME = "buddy_db"
DATABASE_SSLMODE = "disable"
DEFAULT_POSTGRES_DSN = f"postgresql://{DATABASE_USER}:{DATABASE_PASSWORD}@{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_NAME}?sslmode={DATABASE_SSLMODE}"


class __Settings(BaseSettings):
    model_config = SettingsConfigDict(extra="ignore")

    jwt_secret_key: str = "not_so_secure_secret"
    database_url: str = DEFAULT_POSTGRES_DSN
    jwt_expire_minutes: int = 30
    timezone: TimeZoneName = TimeZoneName("UTC")
    jwt_algorithm: str = "HS256"
    refresh_tokens_per_user: int = 2
    openai_api_key: str | None = None
    google_ai_api_key: str | None = None

    @property
    def tzinfo(self):
        return pytz.timezone(self.timezone)


settings = __Settings()
