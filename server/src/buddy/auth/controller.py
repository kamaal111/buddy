from typing import Annotated, Any, Generator, Protocol

from fastapi import Depends
from sqlmodel import Session

from buddy.auth.exceptions import InvalidCredentials
from buddy.auth.models import User
from buddy.auth.schemas import (
    LoginResponse,
    RegisterResponse,
    SessionResponse,
    UserPayload,
    UserResponse,
)
from buddy.auth.utils.jwt_utils import encode_jwt
from buddy.database import Databaseable, get_database


class AuthControllable(Protocol):
    database: Databaseable

    def register(self, email: str, password: str) -> RegisterResponse: ...

    def login(self, email: str, password: str) -> LoginResponse: ...

    def session(self, user: User) -> SessionResponse: ...


class AuthController(AuthControllable):
    def __init__(self, database: Databaseable) -> None:
        self.database = database

    def register(self, email, password) -> RegisterResponse:
        validated_payload = UserPayload(email=email, password=password)
        with Session(self.database.engine) as session:
            User.create(payload=validated_payload, session=session)

            return RegisterResponse(detail="Created")

    def login(self, email, password) -> LoginResponse:
        validated_payload = UserPayload(email=email, password=password)
        with Session(self.database.engine) as session:
            user = User.get_by_email(email=validated_payload.email, session=session)
            if user is None:
                raise InvalidCredentials

            if not user.verify_password(raw_password=validated_payload.password):
                raise InvalidCredentials

            access_token = encode_jwt(user)

        return LoginResponse(
            access_token=access_token, token_type="bearer", detail="OK"
        )

    def session(self, user) -> SessionResponse:
        return SessionResponse(detail="OK", user=UserResponse(email=user.email))


def get_auth_controller(
    database: Annotated[Databaseable, Depends(get_database)],
) -> Generator[AuthControllable, Any, None]:
    controller = AuthController(database=database)
    yield controller
