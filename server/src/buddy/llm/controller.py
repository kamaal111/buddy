from __future__ import annotations

import uuid
from typing import Annotated, Protocol

from fastapi import Depends
from sqlmodel import Session

from buddy.auth.middleware import get_request_user
from buddy.auth.models import User
from buddy.database import Databaseable, get_database
from buddy.exceptions import BuddyNotFoundError
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
    ListChatMessagesResponse,
)
from buddy.utils.datetime_utils import datetime_now_with_timezone


class LLMControllable(Protocol):
    user: User
    database: Databaseable

    def list_chat_rooms(self) -> ChatRoomListResponse: ...

    def list_chat_messages(self, room_id: uuid.UUID) -> ListChatMessagesResponse: ...

    def create_chat_message(
        self, payload: CreateChatMessagePayload
    ) -> CreateChatMessageResponse: ...


class LLMController(LLMControllable):
    user: User
    database: Databaseable

    def __init__(self, database: Databaseable, user: User):
        self.database = database
        self.user = user

    def list_chat_rooms(self) -> ChatRoomListResponse:
        owner_id = self.user.id
        assert owner_id is not None

        with Session(self.database.engine) as session:

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

    def list_chat_messages(self, room_id) -> ListChatMessagesResponse:
        owner_id = self.user.id
        assert owner_id is not None

        with Session(self.database.engine) as session:
            room = ChatRoom.get_by_id(id=room_id, owner_id=owner_id, session=session)
            if room is None:
                raise BuddyNotFoundError

            return ListChatMessagesResponse(detail="OK", data=room.validated_messages())

    def create_chat_message(self, payload) -> CreateChatMessageResponse:
        request_time = datetime_now_with_timezone()
        selected_model = get_users_model_by_key(
            user=self.user, llm_key=payload.llm_key, provider=payload.llm_provider
        )
        if selected_model is None:
            raise LLMNotAllowed

        provider = get_users_provider_by_model(user=self.user, model=selected_model)
        if provider is None:
            raise LLMNotAllowed

        asking_user_id = self.user.id
        assert asking_user_id is not None

        messages: list[ChatRoomMessage] = []
        existing_room: ChatRoom | None = None
        with Session(self.database.engine) as session:
            if room_id := payload.room_id:
                existing_room = ChatRoom.get_by_id(
                    id=room_id, owner_id=asking_user_id, session=session
                )
                if existing_room is None:
                    raise LLMNotAllowed

                messages = existing_room.validated_messages()

        question = ChatRoomMessage(
            role="user",
            content=payload.message,
            llm_provider=payload.llm_provider,
            llm_key=payload.llm_key,
            date=request_time,
        )
        messages.append(question)
        response = provider.chat(
            llm_model=selected_model,
            messages=messages,
        )
        response_time = datetime_now_with_timezone()
        with Session(self.database.engine) as session:
            if existing_room:
                room = existing_room.add_messages(
                    messages=[
                        question,
                        response,
                    ],
                    session=session,
                )
            else:
                room = ChatRoom.create(
                    payload=CreateChatRoomPayload(
                        question=question,
                        answer=response,
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
                llm_key=payload.llm_key,
                llm_provider=payload.llm_provider,
                title=room.title,
            )


async def get_llm_controller(
    database: Annotated[Databaseable, Depends(get_database)],
    user: Annotated[User, Depends(get_request_user)],
) -> LLMControllable:
    return LLMController(database=database, user=user)
