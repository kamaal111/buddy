from typing import Annotated

from fastapi import Depends, Header
from sqlmodel import Session

from buddy.auth.exceptions import InvalidCredentials
from buddy.auth.models import User
from buddy.auth.utils.jwt_utils import decode_jwt
from buddy.database import Databaseable, get_database


def get_request_user(
    authorization: Annotated[str, Header()],
    database: Annotated[Databaseable, Depends(get_database)],
):
    split_authorization = authorization.split(" ")
    if len(split_authorization) != 2:
        raise InvalidCredentials

    if split_authorization[0].lower() != "bearer":
        raise InvalidCredentials

    try:
        claims = decode_jwt(token=split_authorization[1])
    except Exception as e:
        raise InvalidCredentials from e

    with Session(database.engine) as session:
        user = User.get_by_id(id=int(claims.sub), session=session)
        if user is None:
            raise InvalidCredentials

        yield user
