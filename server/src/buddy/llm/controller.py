from __future__ import annotations

from typing import Annotated, Protocol

from fastapi import Depends

from buddy.auth.middleware import get_request_user
from buddy.auth.models import User
from buddy.llm.exceptions import LLMNotAllowed
from buddy.llm.providers import (
    get_users_model_by_key,
    get_users_provider_by_model,
)
from buddy.llm.schemas import (
    CreateChatMessagePayload,
    CreateChatMessageResponse,
    LLMMessage,
)


class LLMControllable(Protocol):
    user: User

    def create_chat_message(
        self, payload: CreateChatMessagePayload
    ) -> CreateChatMessageResponse: ...


class LLMController(LLMControllable):
    user: User

    def __init__(self, user: User):
        self.user = user

    def create_chat_message(self, payload) -> CreateChatMessageResponse:
        selected_model = get_users_model_by_key(
            user=self.user, llm_key=payload.llm_key, provider=payload.llm_provider
        )
        if selected_model is None:
            raise LLMNotAllowed

        provider = get_users_provider_by_model(user=self.user, model=selected_model)
        if provider is None:
            raise LLMNotAllowed

        response = provider.chat(
            llm_model=selected_model,
            messages=[LLMMessage(role="user", content=payload.message)],
        )

        return CreateChatMessageResponse(
            detail="OK", role=response.role, content=response.content
        )


async def get_llm_controller(
    user: Annotated[User, Depends(get_request_user)],
) -> LLMControllable:
    return LLMController(user=user)
