from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import ARRAY, JSON, Column, DateTime
from sqlmodel import Field, SQLModel, Session, select

from buddy.auth.models import User
from buddy.exceptions import BuddyBadRequestError
from buddy.llm.schemas import CreateChatRoomPayload, LLMMessage
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

    def get_owner(self, session: Session) -> User | None:
        query = select(User).where(User.id == self.owner_id).limit(1)

        return session.exec(query).first()

    def validated_messages(self) -> list[LLMMessage]:
        return list(map(lambda message: LLMMessage(**message), self.messages))

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
