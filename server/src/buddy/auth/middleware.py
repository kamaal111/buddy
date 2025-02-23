from typing import Annotated, Any, Generator

from fastapi import Depends, Header
from sqlmodel import Session

from buddy.auth.models import User
from buddy.auth.utils.jwt_utils import decode_authorization_token
from buddy.database import Databaseable, get_database


def get_request_user(
    authorization: Annotated[str, Header()],
    database: Annotated[Databaseable, Depends(get_database)],
) -> Generator[User | None, Any, None]:
    claims = decode_authorization_token(
        authorization_token=authorization, verify_exp=True
    )
    if claims is None:
        return None

    with Session(database.engine) as session:
        user = User.get_by_id(id=int(claims.sub), session=session)
        if user is None:
            return None

        yield user
