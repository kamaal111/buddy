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


class LLMChatResponseMessage(BaseModel):
    role: AssistantMessageRole
    content: str


class CreateChatMessagePayload(BaseModel):
    llm_provider: str = Field(..., min_length=1)
    llm_key: str = Field(..., min_length=1)
    message: str = Field(..., min_length=1)

    @field_validator("message", "llm_key", "llm_provider", mode="before")
    @classmethod
    def strip_whitespaces(cls, v: str) -> str:
        return v.strip()


class CreateChatMessageResponse(CreatedResponse, LLMChatResponseMessage):
    room_id: uuid.UUID
    date: datetime


class ChatRoomMessage(LLMMessage):
    llm_provider: str
    llm_key: str
    date: datetime


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
