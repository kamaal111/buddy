from functools import reduce

from buddy.llm.providers.openai import OpenAIProvider
from buddy.llm.providers.provider import LLMProviderable

Providers = dict[str, LLMProviderable]

__PROVIDERS: list[LLMProviderable] = [OpenAIProvider()]


def __reduce_provider(acc: Providers, provider: LLMProviderable) -> Providers:
    acc[provider.get_key()] = provider

    return acc


PROVIDERS: Providers = reduce(__reduce_provider, __PROVIDERS, {})
