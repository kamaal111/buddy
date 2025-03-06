from typing import Literal

from pydantic import BaseModel


class BuddyErrorDetail(BaseModel):
    type: str
    msg: str


class ErrorResponse(BaseModel):
    detail: list[BuddyErrorDetail]


class OKResponse(BaseModel):
    detail: Literal["OK"]


class CreatedResponse(BaseModel):
    detail: Literal["Created"]
