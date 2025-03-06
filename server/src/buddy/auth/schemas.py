from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, EmailStr, Field

from buddy.llm.schemas import LLMModel
from buddy.schemas import CreatedResponse, OKResponse


class UserPayload(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)


class RegisterResponse(CreatedResponse): ...


class AccessToken(BaseModel):
    access_token: str
    expiry_timestamp: int
    token_type: Literal["bearer"]


class LoginResponse(AccessToken, OKResponse):
    refresh_token: str


class UserResponse(BaseModel):
    email: EmailStr
    tier: str | None


class SessionResponse(OKResponse):
    user: UserResponse
    available_models: list[LLMModel]


class RefreshPayload(BaseModel):
    refresh_token: str


class RefreshResponse(AccessToken, OKResponse): ...
