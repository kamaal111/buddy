from __future__ import annotations

from typing import TYPE_CHECKING, Annotated, Protocol

from fastapi import Depends

from buddy.auth.middleware import get_request_user

if TYPE_CHECKING:
    from buddy.auth.models import User


class LLMControllable(Protocol):
    user: User


class LLMController(LLMControllable):
    user: User

    def __init__(self, user: User):
        self.user = user


async def get_llm_controller(
    user: Annotated[User, Depends(get_request_user)],
) -> LLMControllable:
    return LLMController(user=user)
