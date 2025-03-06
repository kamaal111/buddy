from http import HTTPStatus

from fastapi import HTTPException
from pydantic import BaseModel, ValidationError

from buddy.schemas import BuddyErrorDetail


class BuddyError(HTTPException):
    def __init__(
        self,
        status_code: HTTPStatus,
        details: list[BuddyErrorDetail],
        headers: dict[str, str] | None = None,
    ):
        super().__init__(status_code, list(map(_base_model_as_dict, details)), headers)


class BuddyInternalError(BuddyError):
    def __init__(self, headers=None):
        super().__init__(
            HTTPStatus.INTERNAL_SERVER_ERROR,
            [BuddyErrorDetail(msg="Something went wrong", type="internal_error")],
            headers,
        )


class BuddyBadRequestError(BuddyError):
    def __init__(self, headers=None):
        super().__init__(
            HTTPStatus.BAD_REQUEST,
            [BuddyErrorDetail(msg="Invalid payload", type="invalid_payload")],
            headers,
        )


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


def _base_model_as_dict(base_model: BaseModel):
    return base_model.model_dump()
