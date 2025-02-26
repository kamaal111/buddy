from typing import Annotated, Protocol

from fastapi import Depends

from buddy.auth.middleware import get_request_user
from buddy.auth.models import User
from buddy.llm.schemas import ModelsResponse


class LLMControllable(Protocol):
    user: User

    async def models(self) -> ModelsResponse: ...


class LLMController(LLMControllable):
    user: User

    def __init__(self, user: User):
        self.user = user

    async def models(self) -> ModelsResponse:
        return ModelsResponse()


async def get_llm_controller(
    user: Annotated[User, Depends(get_request_user)],
) -> LLMControllable:
    return LLMController(user=user)
