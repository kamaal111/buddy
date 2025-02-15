from pydantic import BaseModel


class StandardResponse(BaseModel):
    details: str


class RegisterResponse(StandardResponse): ...
