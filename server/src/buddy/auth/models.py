from __future__ import annotations

import binascii
import os
from datetime import datetime
from typing import Sequence

import bcrypt
from pydantic import EmailStr
from sqlalchemy import Column, DateTime
from sqlmodel import Field, SQLModel, Session, col, select

from buddy.auth.exceptions import UserAlreadyExists
from buddy.auth.schemas import UserPayload
from buddy.conf import settings
from buddy.utils.datetime_utils import datetime_now_with_timezone

PASSWORD_HASHING_ENCODING = "utf-8"


class User(SQLModel, table=True):
    __tablename__: str = "user"  # type: ignore

    id: int | None = Field(default=None, primary_key=True)
    email: EmailStr = Field(unique=True)
    password: str = Field(min_length=8)
    created_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True), nullable=False, default=datetime_now_with_timezone
        ),
    )
    updated_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            nullable=False,
            default=datetime_now_with_timezone,
            onupdate=datetime_now_with_timezone,
        ),
    )

    def verify_password(self, raw_password: str) -> bool:
        return bcrypt.checkpw(
            raw_password.encode(PASSWORD_HASHING_ENCODING),
            self.password.encode(PASSWORD_HASHING_ENCODING),
        )

    @staticmethod
    def get_by_email(email: str, session: Session) -> User | None:
        query = select(User).where(User.email == email).limit(1)

        return session.exec(query).first()

    @staticmethod
    def get_by_id(id: int, session: Session) -> User | None:
        query = select(User).where(User.id == id).limit(1)

        return session.exec(query).first()

    @classmethod
    def create(cls, payload: UserPayload, session: Session, commit=True) -> User:
        existing_user = cls.get_by_email(email=payload.email, session=session)
        if existing_user is not None:
            raise UserAlreadyExists()

        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(
            payload.password.encode(PASSWORD_HASHING_ENCODING), salt
        ).decode(PASSWORD_HASHING_ENCODING)
        user = User(email=payload.email, password=hashed_password)

        session.add(user)
        if commit:
            session.commit()

        return user


class UserToken(SQLModel, table=True):
    __tablename__: str = "user_token"  # type: ignore

    id: int | None = Field(default=None, primary_key=True)
    key: str = Field()
    user_id: int = Field(default=None, foreign_key=f"{User.__tablename__}.id")
    created_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True), nullable=False, default=datetime_now_with_timezone
        ),
    )

    @staticmethod
    def get_all_for_user(user: User, session: Session) -> Sequence[UserToken]:
        query = (
            select(UserToken)
            .where(UserToken.user_id == user.id)
            .order_by(col(UserToken.created_at).asc())
        )

        return session.exec(query).all()

    @staticmethod
    def get_last_created_token_for_user(
        user: User, session: Session
    ) -> UserToken | None:
        query = (
            select(UserToken)
            .where(UserToken.user_id == user.id)
            .order_by(col(UserToken.created_at).desc())
            .limit(1)
        )

        return session.exec(query).first()

    @classmethod
    def create(cls, user: User, session: Session) -> UserToken:
        tokens_for_user = cls.get_all_for_user(user=user, session=session)
        tokens_to_delete_amount = len(tokens_for_user) - (
            settings.refresh_tokens_per_user - 1
        )

        assert len(tokens_for_user) <= settings.refresh_tokens_per_user, (
            "Tokens should have been less then the amount allowed"
        )

        if tokens_to_delete_amount > 0:
            tokens_to_delete = tokens_for_user[:tokens_to_delete_amount]
            for token_to_delete in tokens_to_delete:
                session.delete(token_to_delete)

        token = UserToken(key=cls.__generate_refresh_token(), user_id=user.id)
        session.add(token)

        session.commit()

        return token

    @staticmethod
    def __generate_refresh_token() -> str:
        return binascii.hexlify(os.urandom(20)).decode()
