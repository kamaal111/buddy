from pydantic import BaseModel, Field, field_validator


class LLMModel(BaseModel):
    provider: str
    key: str
    display_name: str
    description: str


class ChatPayload(BaseModel):
    llm_provider: str = Field(..., min_length=1)
    llm_key: str = Field(..., min_length=1)
    message: str = Field(..., min_length=1)

    @field_validator("message", "llm_key", "llm_provider", mode="before")
    @classmethod
    def strip_whitespaces(cls, v: str) -> str:
        return v.strip()


class ChatResponse(BaseModel): ...
