from datetime import datetime, timedelta

import jwt
from pydantic import BaseModel

from buddy.auth.models import User
from buddy.conf import settings


def encode_jwt(user: User) -> str:
    now = datetime.now(settings.tzinfo)
    expire = datetime.now(settings.tzinfo) + timedelta(
        minutes=settings.jwt_expire_minutes
    )

    return jwt.encode(
        {"sub": str(user.id), "exp": expire, "iat": now},
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


class DecodedJWTToken(BaseModel):
    sub: str
    exp: int
    iat: int


def decode_jwt(token: str) -> DecodedJWTToken:
    decoded_token = jwt.decode(
        token,
        settings.jwt_secret_key,
        algorithms=[settings.jwt_algorithm],
        options={
            "require": ["exp", "iat", "sub"],
            "verify_exp": True,
            "verify_signature": True,
            "verify_iat": True,
            "verify_sub": True,
        },
    )

    return DecodedJWTToken(**decoded_token)
