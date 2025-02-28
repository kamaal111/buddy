from pydantic import BaseModel


class LLMModel(BaseModel):
    provider: str
    key: str
