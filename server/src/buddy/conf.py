import pytz
from pydantic_extra_types.timezone_name import TimeZoneName
from pydantic_settings import BaseSettings, SettingsConfigDict


class __Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    jwt_secret_key: str = "not_so_secure_secret"
    database_url: str = "sqlite:///database.db"
    jwt_expire_minutes: int = 30
    timezone: TimeZoneName = TimeZoneName("UTC")
    jwt_algorithm: str = "HS256"

    @property
    def tzinfo(self):
        return pytz.timezone(self.timezone)


settings = __Settings()
