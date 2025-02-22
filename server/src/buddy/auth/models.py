from __future__ import annotations

from datetime import datetime

import bcrypt
from pydantic import EmailStr
from sqlalchemy import Column, DateTime
from sqlmodel import Field, SQLModel, Session, select

from buddy.auth.exceptions import UserAlreadyExists
from buddy.auth.schemas import UserPayload
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
        existing_user = User.get_by_email(email=payload.email, session=session)
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
