from pydantic import BaseModel


class LLMModel(BaseModel):
    provider: str
    key: str
    display_name: str
    description: str
