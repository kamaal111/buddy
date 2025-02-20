from http import HTTPStatus

from buddy.exceptions import BuddyError, BuddyErrorDetail


class UserAlreadyExists(BuddyError):
    def __init__(self, headers: dict[str, str] | None = None):
        super().__init__(
            HTTPStatus.CONFLICT,
            [BuddyErrorDetail(msg="User already exists", type="user_already_exists")],
            headers,
        )
