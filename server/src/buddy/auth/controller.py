from datetime import datetime, timedelta
from typing import Annotated, Any, Generator, Protocol

import jwt
from fastapi import Depends
from sqlmodel import Session

from buddy.auth.exceptions import InvalidCredentials
from buddy.auth.models import User
from buddy.auth.schemas import LoginResponse, RegisterResponse, UserSchema
from buddy.conf import settings
from buddy.database import Databaseable, get_database


class AuthControllable(Protocol):
    database: Databaseable

    def register(self, email: str, password: str) -> RegisterResponse: ...

    def login(self, email: str, password: str) -> LoginResponse: ...


class AuthController:
    def __init__(self, database: Databaseable) -> None:
        self.database = database

    def register(self, email: str, password: str) -> RegisterResponse:
        validated_payload = UserSchema(email=email, password=password)
        with Session(self.database.engine) as session:
            User.create(payload=validated_payload, session=session)

            return RegisterResponse(detail="Created")

    def login(self, email: str, password: str) -> LoginResponse:
        validated_payload = UserSchema(email=email, password=password)
        with Session(self.database.engine) as session:
            user = User.get_by_email(email=validated_payload.email, session=session)
            if user is None:
                raise InvalidCredentials

            if not user.verify_password(raw_password=validated_payload.password):
                raise InvalidCredentials

            expire = datetime.now(settings.tzinfo) + timedelta(
                minutes=settings.jwt_expire_minutes
            )
            access_token = jwt.encode(
                {"sub": str(user.id), "exp": expire},
                settings.jwt_secret_key,
                algorithm=settings.jwt_algorithm,
            )

        return LoginResponse(
            access_token=access_token, token_type="bearer", detail="OK"
        )


def get_auth_controller(
    database: Annotated[Databaseable, Depends(get_database)],
) -> Generator[AuthControllable, Any, None]:
    controller = AuthController(database=database)
    yield controller
