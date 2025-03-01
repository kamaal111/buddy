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
from buddy.llm.schemas import ChatPayload, ChatResponse


class LLMControllable(Protocol):
    user: User

    def chat(self, payload: ChatPayload) -> ChatResponse: ...


class LLMController(LLMControllable):
    user: User

    def __init__(self, user: User):
        self.user = user

    def chat(self, payload) -> ChatResponse:
        selected_model = get_users_model_by_key(
            user=self.user, llm_key=payload.llm_key, provider=payload.llm_provider
        )
        if selected_model is None:
            raise LLMNotAllowed

        provider = get_users_provider_by_model(user=self.user, model=selected_model)
        if provider is None:
            raise LLMNotAllowed

        print(provider)

        return ChatResponse()


async def get_llm_controller(
    user: Annotated[User, Depends(get_request_user)],
) -> LLMControllable:
    return LLMController(user=user)
