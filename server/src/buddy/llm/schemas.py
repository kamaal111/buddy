import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator

from buddy.schemas import CreatedResponse, OKResponse

AssistantMessageRole = Literal["assistant"]
MessageRoles = Literal["user"] | AssistantMessageRole


class LLMModel(BaseModel):
    provider: str
    key: str
    display_name: str
    description: str


class LLMMessage(BaseModel):
    role: MessageRoles
    content: str


class CreateChatMessagePayload(BaseModel):
    room_id: uuid.UUID | None = None
    llm_provider: str = Field(..., min_length=1)
    llm_key: str = Field(..., min_length=1)
    message: str = Field(..., min_length=1)

    @field_validator("message", "llm_key", "llm_provider", mode="before")
    @classmethod
    def strip_whitespaces(cls, v: str) -> str:
        return v.strip()


class ChatRoomMessage(LLMMessage):
    llm_provider: str
    llm_key: str
    date: datetime

    @property
    def as_llm_message(self) -> LLMMessage:
        return LLMMessage(role=self.role, content=self.content)


class CreateChatMessageResponse(CreatedResponse, ChatRoomMessage):
    room_id: uuid.UUID
    title: str
    date: datetime
    updated_at: datetime


class CreateChatRoomPayload(BaseModel):
    question: ChatRoomMessage
    answer: ChatRoomMessage
    asking_user_id: int


class ChatRoomListItem(BaseModel):
    room_id: uuid.UUID
    title: str
    messages_count: int
    created_at: datetime
    updated_at: datetime


class ChatRoomListResponse(OKResponse):
    data: list[ChatRoomListItem]


class ListChatMessagesResponse(OKResponse):
    data: list[ChatRoomMessage]
