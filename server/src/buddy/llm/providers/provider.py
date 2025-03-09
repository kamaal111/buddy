from __future__ import annotations

from typing import TYPE_CHECKING, Generic, Protocol, TypeVar

from pydantic import BaseModel

from buddy.llm.schemas import ChatRoomMessage

if TYPE_CHECKING:
    from buddy.auth.models import User
    from buddy.llm.schemas import LLMModel


NativeMessage = TypeVar("NativeMessage", bound=BaseModel)


class LLMProviderable(Protocol, Generic[NativeMessage]):
    def chat(
        self, llm_model: LLMModel, messages: list[ChatRoomMessage]
    ) -> ChatRoomMessage: ...

    def get_model_list_available_to_user(self, user: User) -> list[LLMModel]: ...

    def get_name(self) -> str: ...

    def get_all_models(self) -> list[LLMModel]: ...

    def transform_messages_to_native(
        self, messages: list[ChatRoomMessage]
    ) -> list[NativeMessage]: ...
