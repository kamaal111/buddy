from http import HTTPStatus

from buddy.exceptions import BuddyError
from buddy.schemas import BuddyErrorDetail


class LLMNotAllowed(BuddyError):
    def __init__(self, headers=None):
        super().__init__(
            HTTPStatus.FORBIDDEN,
            [
                BuddyErrorDetail(
                    msg="Selected LLM is not allowed", type="llm_not_allowed"
                )
            ],
            headers,
        )
