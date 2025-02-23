from sqlmodel import Session

from buddy.auth.models import UserToken


def test_user_token(database, default_user):
    with Session(database.engine) as session:
        token1 = UserToken.create(user=default_user, session=session)
        UserToken.create(user=default_user, session=session)
        token3 = UserToken.create(user=default_user, session=session)

        tokens = UserToken.get_all_for_user(user=default_user, session=session)

        assert len(tokens) == 2
        assert token1.id not in map(lambda token: token.id, tokens)

        token = UserToken.get_last_created_token_for_user(
            user=default_user, session=session
        )

        assert token is not None
        assert token3.id is token.id
