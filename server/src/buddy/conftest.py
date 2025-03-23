# ruff: noqa: E402
import os
from pathlib import Path

from dotenv import load_dotenv

project_root = Path(__file__).parent.parent.parent
env_found = load_dotenv(project_root / ".env.testing")

assert env_found


from http import HTTPStatus
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, create_engine, select
from testcontainers.postgres import PostgresContainer  # type: ignore

from buddy.auth.models import User
from buddy.auth.schemas import LoginResponse, UserPayload
from buddy.database import (
    BaseDatabase,
    Databaseable,
    create_db_and_tables,
    get_database,
)
from buddy.main import app

postgres_port = 5432
postgres_version = (project_root / Path(".postgres-version")).read_text().strip()
postgres_driver = os.getenv("DATABASE_DRIVER")

assert postgres_driver is not None

postgres = PostgresContainer(
    f"postgres:{postgres_version}", port=postgres_port, driver=postgres_driver
)


class DatabaseForTests(BaseDatabase):
    def __init__(self, database_url: str) -> None:
        super().__init__(create_engine(database_url, echo=False))


def get_database_override(database: DatabaseForTests):
    def override():
        yield database

    return override


@pytest.fixture(scope="session")
def database(request: pytest.FixtureRequest):
    postgres.start()

    database_url = f"postgresql+{postgres_driver}://{postgres.username}:{postgres.password}@{postgres.get_container_host_ip()}:{postgres.get_exposed_port(postgres_port)}/{postgres.dbname}"

    def teardown():
        postgres.stop()

    request.addfinalizer(teardown)

    database = DatabaseForTests(database_url)
    create_db_and_tables(database)

    yield database


@pytest.fixture(scope="session")
def default_user_credentials():
    yield UserPayload(email="yami@bulls.io", password="nice_password")


@pytest.fixture(scope="session")
def default_user(database: Databaseable, default_user_credentials: UserPayload):
    with Session(database.engine) as session:
        query = select(User).where(User.email == default_user_credentials.email)
        if user := session.exec(query).first():
            yield user

        yield User.create(payload=default_user_credentials, session=session)


@pytest.fixture(scope="function")
def default_user_login(client, default_user, default_user_credentials) -> LoginResponse:
    login_response = client.post(
        "/app-api/v1/auth/login",
        data=default_user_credentials.model_dump(),
    )
    json_response = login_response.json()

    assert login_response.status_code == HTTPStatus.OK
    assert json_response["detail"] == "OK"
    assert json_response["token_type"] == "bearer"
    assert isinstance(json_response["refresh_token"], str)

    access_token = json_response["access_token"]

    assert isinstance(access_token, str)

    return LoginResponse(**json_response)


@pytest.fixture(scope="function")
def client(database, default_user):
    __client = TestClient(app)
    app.dependency_overrides[get_database] = get_database_override(database)

    try:
        yield __client
    finally:
        app.dependency_overrides.clear()
