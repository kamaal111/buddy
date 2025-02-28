from __future__ import annotations

from typing import TYPE_CHECKING, Protocol

if TYPE_CHECKING:
    from buddy.auth.models import User
    from buddy.llm.schemas import LLMModel


class LLMProviderable(Protocol):
    def get_models_available_to_user(self, user: User) -> list[LLMModel]: ...

    def get_name(self) -> str: ...

    def get_all_models(self) -> list[LLMModel]: ...
