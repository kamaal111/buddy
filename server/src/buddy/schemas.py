from pydantic import BaseModel


class BuddyErrorDetail(BaseModel):
    type: str
    msg: str


class ErrorResponse(BaseModel):
    detail: list[BuddyErrorDetail]
