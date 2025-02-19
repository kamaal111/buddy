from http import HTTPStatus

from fastapi import HTTPException


class UserAlreadyExists(HTTPException):
    def __init__(self, headers: dict[str, str] | None = None) -> None:
        super().__init__(HTTPStatus.CONFLICT, "User already exists", headers)
