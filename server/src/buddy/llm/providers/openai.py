from buddy.llm.providers.provider import LLMProviderable

OPENAI_KEY = "openai"
OPENAI_MODELS = ["gpt-4o"]


class OpenAIProvider(LLMProviderable):
    def get_models_available_to_user(self, user):
        return self.get_all_models()

    def get_key(self):
        return OPENAI_KEY

    def get_all_models(self):
        return OPENAI_MODELS
