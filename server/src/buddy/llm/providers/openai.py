from collections import OrderedDict
from functools import reduce

from buddy.llm.providers.provider import LLMProviderable
from buddy.llm.schemas import LLMModel
from buddy.money.tiers import UserTiers

_NAME = "openai"
_MODELS_MAPPED_BY_TIER: OrderedDict[UserTiers, list[LLMModel]] = OrderedDict(
    [(UserTiers.FREE, [LLMModel(provider=_NAME, key="gpt-4o")])]
)


def __reduce_model(
    acc: list[LLMModel], model_key_value: tuple[UserTiers, list[LLMModel]]
) -> list[LLMModel]:
    models_to_add: list[LLMModel] = []
    for model in model_key_value[1]:
        if model not in acc:
            models_to_add.append(model)

    return acc + models_to_add


_MODELS: list[LLMModel] = reduce(__reduce_model, _MODELS_MAPPED_BY_TIER.items(), [])


class OpenAIProvider(LLMProviderable):
    def get_models_available_to_user(self, user) -> list[LLMModel]:
        tier = user.formatted_tier
        assert tier is not None

        if tier is None:
            return []

        return _MODELS_MAPPED_BY_TIER.get(tier, [])

    def get_name(self):
        return _NAME

    def get_all_models(self):
        return _MODELS
