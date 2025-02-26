from sqlmodel import Session

from buddy.auth.models import User
from buddy.auth.utils.jwt_utils import decode_authorization_token
from buddy.database import Databaseable


def get_user_by_authorization_token(
    authorization: str, database: Databaseable, verify_exp=True
):
    claims = decode_authorization_token(
        authorization_token=authorization, verify_exp=verify_exp
    )
    if claims is None:
        return None

    with Session(database.engine) as session:
        user = User.get_by_id(id=int(claims.sub), session=session)
        if user is None:
            return None

        return user
