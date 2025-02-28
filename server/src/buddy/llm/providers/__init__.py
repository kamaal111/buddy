from __future__ import annotations

from collections import OrderedDict
from functools import reduce
from itertools import chain
from typing import TYPE_CHECKING

from buddy.llm.providers.openai import OpenAIProvider

if TYPE_CHECKING:
    from buddy.auth.models import User
    from buddy.llm.providers.provider import LLMProviderable
    from buddy.llm.schemas import LLMModel

    Providers = OrderedDict[str, LLMProviderable]

__PROVIDERS: list[LLMProviderable] = [OpenAIProvider()]


def __reduce_provider(acc: Providers, provider: LLMProviderable) -> Providers:
    acc[provider.get_name()] = provider

    return acc


PROVIDERS: Providers = reduce(__reduce_provider, __PROVIDERS, OrderedDict())


def get_models_available_to_user(user: User) -> chain[LLMModel]:
    return chain.from_iterable(
        map(
            lambda provider: provider.get_models_available_to_user(user),
            PROVIDERS.values(),
        )
    )
