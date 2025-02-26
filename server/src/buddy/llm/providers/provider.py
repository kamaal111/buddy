from typing import Protocol

from buddy.auth.models import User


class LLMProviderable(Protocol):
    def get_models_available_to_user(self, user: User) -> list[str]: ...

    def get_key(self) -> str: ...

    def get_all_models(self) -> list[str]: ...
