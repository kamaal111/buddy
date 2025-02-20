from dataclasses import asdict, dataclass
from http import HTTPStatus

from fastapi import HTTPException


@dataclass
class BuddyErrorDetail:
    msg: str
    type: str


class BuddyError(HTTPException):
    def __init__(
        self,
        status_code: HTTPStatus,
        details: list[BuddyErrorDetail],
        headers: dict[str, str] | None = None,
    ):
        super().__init__(status_code, list(map(asdict, details)), headers)
