from dataclasses import asdict, dataclass
from http import HTTPStatus

from fastapi import HTTPException
from pydantic import ValidationError


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


class BuddyValidationError(HTTPException):
    def __init__(
        self,
        cause_exception: ValidationError,
        headers: dict[str, str] | None = None,
    ):
        super().__init__(
            HTTPStatus.UNPROCESSABLE_ENTITY,
            cause_exception.errors(
                include_url=False, include_input=False, include_context=False
            ),
            headers,
        )
