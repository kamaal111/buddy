from http import HTTPStatus

from buddy.exceptions import BuddyError
from buddy.schemas import BuddyErrorDetail


class UserAlreadyExists(BuddyError):
    def __init__(self, headers: dict[str, str] | None = None):
        super().__init__(
            HTTPStatus.CONFLICT,
            [BuddyErrorDetail(msg="User already exists", type="user_already_exists")],
            headers,
        )


class InvalidCredentials(BuddyError):
    def __init__(self, headers: dict[str, str] | None = None) -> None:
        super().__init__(
            HTTPStatus.UNAUTHORIZED,
            [BuddyErrorDetail(msg="Invalid credentials", type="invalid_credentials")],
            headers,
        )
