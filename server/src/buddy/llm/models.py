from __future__ import annotations

import uuid
from datetime import datetime
from typing import Sequence

from sqlalchemy import ARRAY, JSON, Column, DateTime
from sqlmodel import Field, SQLModel, Session, col, select

from buddy.auth.models import User
from buddy.exceptions import BuddyBadRequestError
from buddy.llm.schemas import ChatRoomMessage, CreateChatRoomPayload
from buddy.utils.datetime_utils import datetime_now_with_timezone


class ChatRoom(SQLModel, table=True):
    __tablename__: str = "chat_room"  # type: ignore

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    created_at: datetime = Field(
        sa_column=Column(DateTime(timezone=True), nullable=False),
        default_factory=datetime_now_with_timezone,
    )
    updated_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            nullable=False,
            onupdate=datetime_now_with_timezone,
        ),
        default_factory=datetime_now_with_timezone,
    )
    title: str = Field(min_length=1)
    messages: list = Field(
        default_factory=list, sa_column=Column(ARRAY(JSON), nullable=False)
    )
    owner_id: int = Field(default=None, foreign_key=f"{User.__tablename__}.id")

    def validated_messages(self) -> list[ChatRoomMessage]:
        return sorted(
            map(lambda message: ChatRoomMessage(**message), self.messages),
            key=lambda message: message.date,
            reverse=True,
        )

    def add_messages(
        self, messages: list[ChatRoomMessage], session: Session
    ) -> ChatRoom:
        all_messages = self.validated_messages()
        all_messages.extend(messages)
        self.messages = list(
            map(lambda message: message.model_dump(mode="json"), all_messages)
        )

        session.add(self)
        session.commit()

        room = self
        session.refresh(room)

        return room

    @staticmethod
    def list_for_owner(owner_id: int, session: Session) -> Sequence[ChatRoom]:
        query = (
            select(ChatRoom)
            .where(ChatRoom.owner_id == owner_id)
            .order_by(col(ChatRoom.updated_at).asc())
        )

        return session.exec(query).all()

    @staticmethod
    def get_by_id(id: uuid.UUID, owner_id: int, session: Session) -> ChatRoom | None:
        query = (
            select(ChatRoom)
            .where(ChatRoom.id == id)
            .where(ChatRoom.owner_id == owner_id)
            .limit(1)
        )

        return session.exec(query).first()

    @staticmethod
    def create(
        payload: CreateChatRoomPayload, session: Session, commit=True
    ) -> ChatRoom:
        if len(payload.question.content.strip()) == 0:
            raise BuddyBadRequestError

        messages = [
            payload.question.model_dump(mode="json"),
            payload.answer.model_dump(mode="json"),
        ]

        asking_user = User.get_by_id(id=payload.asking_user_id, session=session)
        if asking_user is None:
            raise BuddyBadRequestError

        assert asking_user.id is not None

        room = ChatRoom(
            title=payload.question.content.strip()[:16],
            messages=messages,
            owner_id=asking_user.id,
        )

        session.add(room)
        if commit:
            session.commit()

        return room
