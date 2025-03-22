from sqlmodel import Session

from buddy.auth.models import UserToken


def test_user_token(database, default_user):
    with Session(database.engine) as session:
        token1 = UserToken.create(user=default_user, session=session)
        UserToken.create(user=default_user, session=session)
        UserToken.create(user=default_user, session=session)
        UserToken.create(user=default_user, session=session)
        token5 = UserToken.create(user=default_user, session=session)

        tokens = UserToken.get_all_for_user(user=default_user, session=session)

        assert len(tokens) == 4
        for token in tokens:
            assert not token.verify_key(token1)

        token = UserToken.get_last_created_token_for_user(
            user=default_user, session=session
        )

        assert token is not None
        assert token.verify_key(token5)
