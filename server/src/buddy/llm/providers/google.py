from collections import OrderedDict
from functools import reduce
from typing import Literal

from google import genai  # type: ignore
from pydantic import BaseModel

from buddy.conf import settings
from buddy.exceptions import BuddyInternalError
from buddy.llm.providers.provider import LLMProviderable
from buddy.llm.schemas import ChatRoomMessage, LLMModel
from buddy.money.tiers import UserTiers
from buddy.utils.datetime_utils import datetime_now_with_timezone
from buddy.utils.logger_utils import get_logger

logger = get_logger()

_NAME = "google"
_MODELS_MAPPED_BY_TIER: OrderedDict[UserTiers, list[LLMModel]] = OrderedDict(
    [
        (
            UserTiers.FREE,
            [
                LLMModel(
                    provider=_NAME,
                    key="gemini-2.0-flash-lite",
                    display_name="Gemini 2.0 Flash-Lite",
                    description="Lightning-fast and cheapest AI. Incredibly efficient reasoning model by Google.",
                ),
                LLMModel(
                    provider=_NAME,
                    key="gemini-2.0-flash",
                    display_name="Gemini 2.0 Flash",
                    description="Lightning-fast AI. Incredibly efficient reasoning model by Google.",
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


class GoogleProviderNativeMessagePart(BaseModel):
    text: str


class GoogleProviderNativeMessage(BaseModel):
    role: Literal["model", "user"]
    parts: list[GoogleProviderNativeMessagePart]


class GoogleProvider(LLMProviderable[GoogleProviderNativeMessage]):
    client: genai.Client

    def __init__(self):
        self.client = genai.Client(api_key=settings.google_ai_api_key)

    def chat(self, llm_model, messages) -> ChatRoomMessage:
        assert llm_model.provider == _NAME
        assert llm_model.key in map(lambda model: model.key, _MODELS)
        assert self.client is not None

        pre_calculated_token_count = self.client.models.count_tokens(
            model=llm_model.key, contents=messages[-1].content
        )
        logger.info(
            f"Google AI completion on model '{llm_model.key}' made with '{pre_calculated_token_count}' tokens pre calculated"
        )
        native_messages = self.transform_messages_to_native(messages)
        response = self.client.models.generate_content(
            model=llm_model.key,
            contents=list(
                map(lambda message: message.model_dump(mode="python"), native_messages)
            ),
        )
        if response.usage_metadata is None:
            logger.warning("Usage from Google AI completion is None")
            raise BuddyInternalError

        if not response.text:
            logger.warning(
                "No content available from Google AI completion response message"
            )
            raise BuddyInternalError

        response_time = datetime_now_with_timezone()

        return ChatRoomMessage(
            role="assistant",
            content=response.text,
            llm_key=llm_model.key,
            llm_provider=llm_model.provider,
            date=response_time,
        )

    def get_name(self):
        return _NAME

    def get_model_list_available_to_user(self, user):
        tier = user.formatted_tier
        assert tier is not None

        if tier is None:
            return []

        return _MODELS_MAPPED_BY_TIER.get(tier, [])

    def get_all_models(self) -> list[LLMModel]:
        return _MODELS

    def transform_messages_to_native(
        self, messages
    ) -> list[GoogleProviderNativeMessage]:
        transformed_messages = []
        for message in messages:
            transformed_messages.append(
                GoogleProviderNativeMessage(
                    role="user" if message.role == "user" else "model",
                    parts=[GoogleProviderNativeMessagePart(text=message.content)],
                )
            )

        return transformed_messages
