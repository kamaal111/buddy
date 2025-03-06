from __future__ import annotations

from typing import Annotated, Protocol

from fastapi import Depends
from sqlmodel import Session

from buddy.auth.middleware import get_request_user
from buddy.auth.models import User
from buddy.database import Databaseable, get_database
from buddy.llm.exceptions import LLMNotAllowed
from buddy.llm.models import ChatRoom
from buddy.llm.providers import (
    get_users_model_by_key,
    get_users_provider_by_model,
)
from buddy.llm.schemas import (
    ChatRoomListItem,
    ChatRoomListResponse,
    ChatRoomMessage,
    CreateChatMessagePayload,
    CreateChatMessageResponse,
    CreateChatRoomPayload,
    LLMMessage,
)
from buddy.utils.datetime_utils import datetime_now_with_timezone


class LLMControllable(Protocol):
    user: User
    database: Databaseable

    def list_chat_rooms(self) -> ChatRoomListResponse: ...

    def create_chat_room(
        self, payload: CreateChatMessagePayload
    ) -> CreateChatMessageResponse: ...


class LLMController(LLMControllable):
    user: User
    database: Databaseable

    def __init__(self, database: Databaseable, user: User):
        self.database = database
        self.user = user

    def list_chat_rooms(self):
        with Session(self.database.engine) as session:
            owner_id = self.user.id
            assert owner_id is not None

            def chat_room_to_response(room: ChatRoom) -> ChatRoomListItem:
                return ChatRoomListItem(
                    room_id=room.id,
                    title=room.title,
                    messages_count=len(room.messages),
                    created_at=room.created_at,
                    updated_at=room.updated_at,
                )

            rooms = list(
                map(
                    chat_room_to_response,
                    ChatRoom.list_for_owner(owner_id=owner_id, session=session),
                )
            )

            return ChatRoomListResponse(detail="OK", data=rooms)

    def create_chat_room(self, payload) -> CreateChatMessageResponse:
        request_time = datetime_now_with_timezone()
        selected_model = get_users_model_by_key(
            user=self.user, llm_key=payload.llm_key, provider=payload.llm_provider
        )
        if selected_model is None:
            raise LLMNotAllowed

        provider = get_users_provider_by_model(user=self.user, model=selected_model)
        if provider is None:
            raise LLMNotAllowed

        question = LLMMessage(role="user", content=payload.message)
        response = provider.chat(
            llm_model=selected_model,
            messages=[question],
        )
        response_time = datetime_now_with_timezone()
        with Session(self.database.engine) as session:
            asking_user_id = self.user.id
            assert asking_user_id is not None

            room = ChatRoom.create(
                payload=CreateChatRoomPayload(
                    question=ChatRoomMessage(
                        role=question.role,
                        content=question.content,
                        llm_provider=payload.llm_provider,
                        llm_key=payload.llm_key,
                        date=request_time,
                    ),
                    answer=ChatRoomMessage(
                        role=response.role,
                        content=response.content,
                        llm_provider=payload.llm_provider,
                        llm_key=payload.llm_key,
                        date=response_time,
                    ),
                    asking_user_id=asking_user_id,
                ),
                session=session,
            )

            return CreateChatMessageResponse(
                detail="Created",
                role=response.role,
                content=response.content,
                date=response_time,
                room_id=room.id,
            )


async def get_llm_controller(
    database: Annotated[Databaseable, Depends(get_database)],
    user: Annotated[User, Depends(get_request_user)],
) -> LLMControllable:
    return LLMController(database=database, user=user)
