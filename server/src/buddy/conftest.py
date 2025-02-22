import uuid
from http import HTTPStatus
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, create_engine, select

from buddy.auth.models import User
from buddy.auth.schemas import UserPayload
from buddy.database import BaseDatabase, create_db_and_tables, get_database
from buddy.main import app


class DatabaseForTests(BaseDatabase):
    def __init__(self, database_name: str) -> None:
        super().__init__(
            create_engine(
                database_name, connect_args={"check_same_thread": False}, echo=False
            )
        )


def get_database_override(database: DatabaseForTests):
    def override():
        yield database

    return override


@pytest.fixture
def database():
    temporary_directory = __get_or_create_temporary_directory_if_not_exists()
    database_path = temporary_directory / f"{uuid.uuid4()}.db"
    database = DatabaseForTests(f"sqlite:///{database_path}")
    create_db_and_tables(database)

    try:
        yield database
    finally:
        database_path.unlink()


@pytest.fixture
def default_user_credentials():
    yield UserPayload(email="yami@bulls.io", password="nice_password")


@pytest.fixture
def default_user(database, default_user_credentials):
    with Session(database.engine) as session:
        query = select(User).where(User.email == default_user_credentials.email)
        if user := session.exec(query).first():
            yield user

        yield User.create(payload=default_user_credentials, session=session)


@pytest.fixture
def default_user_access_token(client, default_user, default_user_credentials) -> str:
    login_response = client.post(
        "/app-api/v1/auth/login",
        data=default_user_credentials.model_dump(),
    )
    json_response = login_response.json()

    assert login_response.status_code == HTTPStatus.OK
    assert json_response["detail"] == "OK"
    assert json_response["token_type"] == "bearer"

    access_token = json_response["access_token"]

    assert isinstance(access_token, str)

    return access_token


@pytest.fixture(scope="function")
def client(database, default_user):
    __client = TestClient(app)
    app.dependency_overrides[get_database] = get_database_override(database)

    try:
        yield __client
    finally:
        app.dependency_overrides.clear()


def __get_or_create_temporary_directory_if_not_exists():
    temporary_directory = Path("tmp")
    temporary_directory.mkdir(parents=True, exist_ok=True)

    return temporary_directory
