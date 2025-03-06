from __future__ import annotations

from typing import TYPE_CHECKING, Protocol

from buddy.llm.schemas import ChatRoomMessage

if TYPE_CHECKING:
    from buddy.auth.models import User
    from buddy.llm.schemas import LLMModel


class LLMProviderable(Protocol):
    def chat(
        self, llm_model: LLMModel, messages: list[ChatRoomMessage]
    ) -> ChatRoomMessage: ...

    def get_model_list_available_to_user(self, user: User) -> list[LLMModel]: ...

    def get_name(self) -> str: ...

    def get_all_models(self) -> list[LLMModel]: ...
