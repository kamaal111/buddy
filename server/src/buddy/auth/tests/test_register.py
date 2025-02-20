from http import HTTPStatus

import pytest
from sqlmodel import Session

from buddy.auth.models import User


def test_register(client, database):
    payload = {"email": "yuno@golden.io", "password": "password-to-keep"}
    register_response = client.post("/auth/register", data=payload)
    json_response = register_response.json()

    assert register_response.status_code == HTTPStatus.CREATED
    assert json_response["detail"] == "Created"

    with Session(database.engine) as session:
        user = User.get_by_email(email=payload["email"], session=session)

        assert user is not None
        assert user.email == payload["email"]
        assert user.verify_password(raw_password=payload["password"])


def test_already_exists(client, default_user_credentials):
    register_response = client.post(
        "/auth/register", data=default_user_credentials.model_dump()
    )
    json_response = register_response.json()

    assert register_response.status_code == HTTPStatus.CONFLICT
    assert json_response["detail"] == [
        {"msg": "User already exists", "type": "user_already_exists"}
    ]


@pytest.mark.parametrize(
    "payload,missing_property",
    [
        ({"password": "password-to-keep"}, "email"),
        ({"email": "yuno@golden.io"}, "password"),
    ],
)
def test_missing_field(client, payload, missing_property):
    register_response = client.post("/auth/register", data=payload)
    json_response = register_response.json()

    assert register_response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY
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
    register_response = client.post("/auth/register", data=payload)
    json_response = register_response.json()

    assert register_response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY
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
    register_response = client.post("/auth/register", data=payload)
    json_response = register_response.json()

    assert register_response.status_code == HTTPStatus.BAD_REQUEST
    assert json_response["detail"] == [
        {
            "type": "string_too_short",
            "loc": ["password"],
            "msg": "String should have at least 8 characters",
        }
    ]
