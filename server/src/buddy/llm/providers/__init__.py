from __future__ import annotations

from collections import OrderedDict
from functools import reduce
from itertools import chain
from typing import TYPE_CHECKING

from buddy.llm.providers.google import GoogleProvider
from buddy.llm.providers.openai import OpenAIProvider

if TYPE_CHECKING:
    from buddy.auth.models import User
    from buddy.llm.providers.provider import LLMProviderable
    from buddy.llm.schemas import LLMModel

    Providers = OrderedDict[str, LLMProviderable]

__PROVIDERS: list[LLMProviderable] = [GoogleProvider(), OpenAIProvider()]


def __reduce_provider(acc: Providers, provider: LLMProviderable) -> Providers:
    acc[provider.get_name()] = provider

    return acc


PROVIDERS: Providers = reduce(__reduce_provider, __PROVIDERS, OrderedDict())


def get_users_model_by_key(user: User, llm_key: str, provider: str) -> LLMModel | None:
    user_models = get_models_grouped_by_provider_available_to_user(user)
    provider_models = user_models.get(provider)
    if provider_models is None:
        return None

    assert len(provider_models) > 0

    selected_model = None
    for provider_model in provider_models:
        if provider_model.key == llm_key:
            selected_model = provider_model
            break

    if selected_model is None:
        return None

    return selected_model


def get_users_provider_by_model(user: User, model: LLMModel) -> LLMProviderable | None:
    selected_model = get_users_model_by_key(
        user=user, llm_key=model.key, provider=model.provider
    )
    if selected_model is None:
        return None

    return PROVIDERS[selected_model.provider]


def get_models_grouped_by_provider_available_to_user(
    user: User,
) -> dict[str, list[LLMModel]]:
    models: dict[str, list[LLMModel]] = {}
    for name, provider in PROVIDERS.items():
        provider_models = provider.get_model_list_available_to_user(user)
        if len(provider_models) == 0:
            continue

        models[name] = provider_models

    return models


def get_model_list_available_to_user(user: User) -> list[LLMModel]:
    return list(
        chain.from_iterable(
            get_models_grouped_by_provider_available_to_user(user).values()
        )
    )
