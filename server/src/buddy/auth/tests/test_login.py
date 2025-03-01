from http import HTTPStatus

import pytest
from sqlmodel import Session

from buddy.auth.models import UserToken
from buddy.auth.utils.jwt_utils import decode_jwt


def test_login(database, default_user, default_user_login):
    claims = decode_jwt(token=default_user_login.access_token)

    assert claims.sub == str(default_user.id)

    with Session(database.engine) as session:
        token = UserToken.get_last_created_token_for_user(
            user=default_user, session=session
        )

        assert token is not None
        assert token.verify_key(default_user_login.refresh_token)


def test_incorrect_password(client, default_user_credentials):
    login_response = client.post(
        "/app-api/v1/auth/login",
        data={**default_user_credentials.model_dump(), "password": "hahahahahahah"},
    )
    json_response = login_response.json()

    assert login_response.status_code == HTTPStatus.UNAUTHORIZED
    assert json_response["detail"] == [
        {"msg": "Invalid credentials", "type": "invalid_credentials"}
    ]


def test_user_does_not_exist(client, default_user_credentials):
    login_response = client.post(
        "/app-api/v1/auth/login",
        data={**default_user_credentials.model_dump(), "email": "kamaal@maal.al"},
    )
    json_response = login_response.json()

    assert login_response.status_code == HTTPStatus.UNAUTHORIZED
    assert json_response["detail"] == [
        {"msg": "Invalid credentials", "type": "invalid_credentials"}
    ]


@pytest.mark.parametrize(
    "payload,missing_property",
    [
        ({"password": "password-to-keep"}, "email"),
        ({"email": "yuno@golden.io"}, "password"),
    ],
)
def test_missing_field(client, payload, missing_property):
    login_response = client.post(
        "/app-api/v1/auth/login",
        data=payload,
    )
    json_response = login_response.json()

    assert login_response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY
    assert json_response["detail"] == [
        {
            "type": "missing",
            "loc": ["body", missing_property],
            "msg": "Field required",
            "input": None,
        }
    ]


def test_invalid_email(client):
    payload = {"email": "yuno@golden", "password": "password-to-keep"}
    login_response = client.post(
        "/app-api/v1/auth/login",
        data=payload,
    )
    json_response = login_response.json()

    assert login_response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY
    assert json_response["detail"] == [
        {
            "type": "value_error",
            "loc": ["body", "email"],
            "msg": "value is not a valid email address: The part after the @-sign is not valid. It should have a period.",
            "input": "yuno@golden",
            "ctx": {
                "reason": "The part after the @-sign is not valid. It should have a period."
            },
        }
    ]


def test_invalid_password(client):
    payload = {"email": "yuno@golden.io", "password": "pass"}
    login_response = client.post(
        "/app-api/v1/auth/login",
        data=payload,
    )
    json_response = login_response.json()

    assert login_response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY
    assert json_response["detail"] == [
        {
            "type": "string_too_short",
            "loc": ["password"],
            "msg": "String should have at least 8 characters",
        }
    ]
