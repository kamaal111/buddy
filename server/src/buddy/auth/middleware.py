from __future__ import annotations

from typing import TYPE_CHECKING, Annotated

from fastapi import Depends, Header

from buddy.auth.exceptions import InvalidCredentials
from buddy.auth.utils.user import get_user_by_authorization_token
from buddy.database import Databaseable, get_database

if TYPE_CHECKING:
    from buddy.auth.models import User


async def get_request_user(
    authorization: Annotated[str, Header()],
    database: Annotated[Databaseable, Depends(get_database)],
) -> User:
    user = get_user_by_authorization_token(
        authorization=authorization, database=database, verify_exp=True
    )
    if user is None:
        raise InvalidCredentials

    return user
