from typing import Literal

from pydantic import BaseModel, EmailStr, Field

from buddy.schemas import OKResponse


class UserPayload(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)


class RegisterResponse(BaseModel):
    detail: Literal["Created"]


class AccessToken(BaseModel):
    access_token: str
    expiry_timestamp: int
    token_type: Literal["bearer"]


class LoginResponse(AccessToken, OKResponse):
    refresh_token: str


class UserResponse(BaseModel):
    email: EmailStr
    tier: str


class SessionResponse(OKResponse):
    user: UserResponse


class RefreshPayload(BaseModel):
    refresh_token: str


class RefreshResponse(AccessToken, OKResponse): ...
