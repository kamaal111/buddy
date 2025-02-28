from typing import Annotated, Protocol

from fastapi import Depends
from sqlmodel import Session

from buddy.auth.exceptions import InvalidCredentials
from buddy.auth.models import User, UserToken
from buddy.auth.schemas import (
    LoginResponse,
    RefreshResponse,
    RegisterResponse,
    SessionResponse,
    UserPayload,
    UserResponse,
)
from buddy.auth.utils.jwt_utils import encode_jwt
from buddy.auth.utils.user import get_user_by_authorization_token
from buddy.database import Databaseable, get_database
from buddy.llm.providers import get_models_available_to_user


class AuthControllable(Protocol):
    database: Databaseable

    def register(self, email: str, password: str) -> RegisterResponse: ...

    def login(self, email: str, password: str) -> LoginResponse: ...

    def session(self, user: User) -> SessionResponse: ...

    def refresh(self, refresh_token: str, authorization: str) -> RefreshResponse: ...


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

            token = encode_jwt(user)
            user_token = UserToken.create(user=user, session=session)

            return LoginResponse(
                detail="OK",
                access_token=token.access_token,
                token_type=token.token_type,
                refresh_token=user_token.key,
                expiry_timestamp=token.expiry_timestamp,
            )

    def session(self, user) -> SessionResponse:
        assert user is not None

        user_tier = user.formatted_tier
        tier = user_tier.name if user_tier is not None else None
        assert tier
        assert isinstance(tier, str)

        response = SessionResponse(
            detail="OK",
            user=UserResponse(email=user.email, tier=tier),
            available_models=get_models_available_to_user(user=user),
        )

        return response

    def refresh(self, refresh_token, authorization) -> RefreshResponse:
        user = get_user_by_authorization_token(
            authorization=authorization, database=self.database, verify_exp=False
        )
        if user is None:
            raise InvalidCredentials

        with Session(self.database.engine) as session:
            user_tokens = UserToken.get_all_for_user(user=user, session=session)
            found_user_token = None
            for user_token in user_tokens:
                if user_token.key == refresh_token:
                    found_user_token = user_token
                    break

            if found_user_token is None:
                raise InvalidCredentials

            token = encode_jwt(user)

            return RefreshResponse(
                detail="OK",
                access_token=token.access_token,
                expiry_timestamp=token.expiry_timestamp,
                token_type=token.token_type,
            )


async def get_auth_controller(
    database: Annotated[Databaseable, Depends(get_database)],
) -> AuthControllable:
    return AuthController(database=database)
