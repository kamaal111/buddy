from typing import Annotated, Any, Generator, Protocol

from fastapi import Depends

from buddy.auth.schemas import RegisterResponse
from buddy.database import Databaseable, get_database


class AuthControllable(Protocol):
    database: Databaseable

    def register(self, email: str, password: str) -> RegisterResponse: ...


class AuthController:
    def __init__(self, database: Databaseable) -> None:
        self.database = database

    def register(self, email: str, password: str) -> RegisterResponse:
        return RegisterResponse(details="Created")


def get_auth_controller(
    database: Annotated[Databaseable, Depends(get_database)],
) -> Generator[AuthControllable, Any, None]:
    controller = AuthController(database=database)
    yield controller
