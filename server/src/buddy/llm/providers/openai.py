from collections import OrderedDict
from functools import reduce

import tiktoken
from openai import OpenAI

from buddy.conf import settings
from buddy.exceptions import BuddyInternalError
from buddy.llm.providers.provider import LLMProviderable
from buddy.llm.schemas import ChatRoomMessage, LLMModel
from buddy.money.tiers import UserTiers
from buddy.utils.datetime_utils import datetime_now_with_timezone
from buddy.utils.logger_utils import get_logger

logger = get_logger()

_NAME = "openai"
_MODELS_MAPPED_BY_TIER: OrderedDict[UserTiers, list[LLMModel]] = OrderedDict(
    [
        (
            UserTiers.FREE,
            [
                LLMModel(
                    provider=_NAME,
                    key="gpt-4o-mini",
                    display_name="GPT-4o mini",
                    description="GPT-4o Mini is great for lightweight, fast, and cost-effective AI tasks.",
                ),
                LLMModel(
                    provider=_NAME,
                    key="o3-mini",
                    display_name="GPT-o3 mini",
                    description="GPT-o3 Mini is a small reasoning model, providing high intelligence at the same cost.",
                ),
                LLMModel(
                    provider=_NAME,
                    key="gpt-4o",
                    display_name="GPT-4o",
                    description="Excels at fast, accurate, and multimodal AI interactions.",
                ),
            ],
        )
    ]
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


class OpenAIProvider(LLMProviderable[ChatRoomMessage]):
    client: OpenAI

    def __init__(self):
        self.client = OpenAI(api_key=settings.openai_api_key)

    def chat(self, llm_model, messages) -> ChatRoomMessage:
        assert llm_model.provider == _NAME
        assert llm_model.key in map(lambda model: model.key, _MODELS)

        encoding = tiktoken.encoding_for_model(llm_model.key)
        pre_calculated_token_count = len(encoding.encode(text=messages[-1].content))
        logger.info(
            f"OpenAI completion on model '{llm_model.key}' made with '{pre_calculated_token_count}' tokens pre calculated"
        )
        response = self.client.chat.completions.create(
            messages=list(
                map(lambda message: message.as_llm_message.model_dump(), messages)
            ),
            model=llm_model.key,
        )
        if response.usage is None:
            logger.warning("Usage from OpenAI completion is None")
            raise BuddyInternalError

        if len(response.choices) == 0:
            logger.warning("No choices available from OpenAI completion response")
            raise BuddyInternalError

        choice = response.choices[0]
        if not choice.message.content:
            logger.warning(
                "No content available from OpenAI completion response message"
            )
            raise BuddyInternalError

        response_time = datetime_now_with_timezone()

        return ChatRoomMessage(
            role=choice.message.role,
            content=choice.message.content,
            llm_key=llm_model.key,
            llm_provider=llm_model.provider,
            date=response_time,
        )

    def transform_messages_to_native(self, messages) -> list[ChatRoomMessage]:
        return messages

    def get_model_list_available_to_user(self, user) -> list[LLMModel]:
        tier = user.formatted_tier
        assert tier is not None

        if tier is None:
            return []

        return _MODELS_MAPPED_BY_TIER.get(tier, [])

    def get_name(self):
        return _NAME

    def get_all_models(self) -> list[LLMModel]:
        return _MODELS
