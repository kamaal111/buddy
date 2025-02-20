from typing import Literal

from pydantic import BaseModel, EmailStr, Field


class UserSchema(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)


class RegisterResponse(BaseModel):
    detail: Literal["Created"]


class AccessToken(BaseModel):
    access_token: str
    token_type: Literal["bearer"]


class LoginResponse(AccessToken):
    detail: Literal["OK"]
