from http import HTTPStatus

from buddy.exceptions import BuddyError


class LLMNotAllowed(BuddyError):
    def __init__(self, headers=None):
        super().__init__(HTTPStatus.FORBIDDEN, "Selected LLM is not allowed", headers)
